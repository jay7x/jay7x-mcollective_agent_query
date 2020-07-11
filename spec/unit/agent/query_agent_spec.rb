# frozen_string_literal: true

require 'spec_helper'
require 'webmock/rspec'

module MCollective::Agent
  describe 'Query' do
    let(:agent_file) { File.join(__dir__, '../../../files/mcollective/agent/query.rb'.split('/')) }
    let(:agent) { MCollective::Test::LocalAgentTest.new('query', agent_file: agent_file).plugin }
    let(:dest) do
      {
        host: '127.0.0.1',
        port: 8200,
      }
    end
    let(:api_url) { "http://#{dest[:host]}:#{dest[:port]}" }
    let(:exporter_content) do
      "# HELP go_gc_duration_seconds A summary of the GC invocation durations.\n" \
      "# TYPE go_gc_duration_seconds summary\n" \
      "  \n" \
      "go_gc_duration_seconds{a=\"b\",quantile=\"0\"} 7.6e-06\n" \
      "go_gc_duration_seconds{a=\"b\",quantile=\"0.25\"} 4.31e-05\n" \
      "go_gc_duration_seconds{a=\"b\",quantile=\"0.5\"} 8.6001e-05\n" \
      "go_gc_duration_seconds{a=\"b\",quantile=\"0.75\"} 0.000145801\n" \
      "go_gc_duration_seconds{a=\"b\",quantile=\"1\"} 0.003476917\n" \
      "go_gc_duration_seconds_sum 22.379136427\n" \
      "go_gc_duration_seconds_count 165860\n"
    end

    WebMock.disable_net_connect!

    describe 'exporter_action' do
      let(:params) do
        {
          url: "#{api_url}/metrics",
          metrics: [
            'go_gc_duration_seconds{a="b",quantile="1"}',
            'go_gc_duration_seconds_count',
          ],
        }
      end

      it 'delegates to #do_request and #grep_metrics' do
        agent.expects(:do_request).with(params[:url], nil, nil, nil).returns(
          code: '200',
          message: 'OK',
          body: exporter_content,
          headers: {
            'content-type' => ['text/plain'],
          },
        )
        result = agent.call(:exporter, url: params[:url], metrics: params[:metrics])
        expect(result).to be_successful
        expect(result).to have_data_items(
          'metrics': {
            'go_gc_duration_seconds{a="b",quantile="1"}': '0.003476917',
            'go_gc_duration_seconds_count': '165860',
          },
        )
      end
    end

    describe 'rest_action' do
      let(:params) do
        {
          url: "#{api_url}/v1/pki/roles/foo",
          method: 'POST',
          headers: {
            'X-Vault-Token' => 'abcdefghijklmn',
            'Content-Type' => 'application/json',
          },
          data: '{"allowed_domains":["example.com"],"allow_subdomains":true}',
        }
      end

      it 'delegates to #do_request' do
        agent.expects(:do_request).with(params[:url], params[:method], params[:headers], params[:data]).returns(
          code: '200',
          message: 'OK',
          body: '{"foo":"bar"}',
          headers: {
            'content-type' => ['application/json'],
          },
        )
        result = agent.call(:rest, url: params[:url], method: params[:method], headers: params[:headers], data: params[:data])
        expect(result).to be_successful
        expect(result).to have_data_items(
          code: '200',
          message: 'OK',
          body: '{"foo":"bar"}',
          headers: {
            'content-type' => ['application/json'],
          },
        )
      end
    end

    # grep_metrics(content, metrics)
    describe '#grep_metrics' do
      context 'with empty content and metrics' do
        let(:params) do
          {
            content: '',
            metrics: [],
          }
        end

        it 'returns empty metrics' do
          res = agent.send(:grep_metrics, params[:content], params[:metrics])
          expect(res).to eq({})
        end
      end

      context 'with empty metrics' do
        let(:params) do
          {
            content: exporter_content,
            metrics: [],
          }
        end

        it 'returns metrics found' do
          res = agent.send(:grep_metrics, params[:content], params[:metrics])
          expect(res).to eq(
            'go_gc_duration_seconds{a="b",quantile="0"}': '7.6e-06',
            'go_gc_duration_seconds{a="b",quantile="0.25"}': '4.31e-05',
            'go_gc_duration_seconds{a="b",quantile="0.5"}': '8.6001e-05',
            'go_gc_duration_seconds{a="b",quantile="0.75"}': '0.000145801',
            'go_gc_duration_seconds{a="b",quantile="1"}': '0.003476917',
            'go_gc_duration_seconds_sum': '22.379136427',
            'go_gc_duration_seconds_count': '165860',
          )
        end
      end

      context 'with metrics(names only)' do
        let(:params) do
          {
            content: exporter_content,
            metrics: [
              'go_gc_duration_seconds',
              'go_gc_duration_seconds_count',
            ],
          }
        end

        it 'returns metrics found' do
          expect(agent.send(:grep_metrics, params[:content], params[:metrics])).to eq(
            'go_gc_duration_seconds{a="b",quantile="0"}': '7.6e-06',
            'go_gc_duration_seconds{a="b",quantile="0.25"}': '4.31e-05',
            'go_gc_duration_seconds{a="b",quantile="0.5"}': '8.6001e-05',
            'go_gc_duration_seconds{a="b",quantile="0.75"}': '0.000145801',
            'go_gc_duration_seconds{a="b",quantile="1"}': '0.003476917',
            'go_gc_duration_seconds_count': '165860',
          )
        end
      end

      context 'with metrics(with labels)' do
        let(:params) do
          {
            content: exporter_content,
            metrics: [
              'go_gc_duration_seconds{a="b",quantile="1"}',
              'go_gc_duration_seconds_count',
            ],
          }
        end

        it 'returns metrics found' do
          expect(agent.send(:grep_metrics, params[:content], params[:metrics])).to eq(
            'go_gc_duration_seconds{a="b",quantile="1"}': '0.003476917',
            'go_gc_duration_seconds_count': '165860',
          )
        end
      end

      context 'with metrics(with wrong labels)' do
        let(:params) do
          {
            content: exporter_content,
            metrics: [
              'go_gc_duration_seconds{quantile="1",a="b"}',
              'go_gc_duration_seconds_count',
            ],
          }
        end

        it 'returns metrics found' do
          expect(agent.send(:grep_metrics, params[:content], params[:metrics])).to eq(
            'go_gc_duration_seconds_count': '165860',
          )
        end
      end
    end

    # do_request(url, method = 'GET', headers = {}, data = '')
    describe '#do_request' do
      let(:sample_headers) do
        {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Host' => "#{dest[:host]}:#{dest[:port]}",
          'User-Agent' => 'MCollective::Agent::Query',
        }
      end

      context 'with GET method' do
        let(:params) { { url: "#{api_url}/v1/pki/roles/foo" } }

        it 'returns response' do
          stub_request(:get, params[:url]).with(
            headers: sample_headers,
          ).to_return(
            status: 200,
            body: '{"data":{"allow_any_name":false}}',
          )

          resp = agent.send(:do_request, params[:url])
          expect(resp[:code]).to eq('200')
          expect(resp[:message]).to eq('')
          expect(resp[:headers]).to eq({})
          expect(resp[:body]).to eq(
            {
              data: {
                allow_any_name: false,
              },
            }.to_json,
          )
        end
      end

      context 'with POST method' do
        let(:params) do
          {
            url: "#{api_url}/v1/pki/roles/foo",
            method: 'POST',
            headers: {
              'X-Vault-Token' => 'abcdefghijklmn',
              'Content-Type' => 'application/json',
            },
            data: '{"allowed_domains":["example.com"],"allow_subdomains":true}',
          }
        end

        it 'returns response' do
          stub_request(:post, params[:url]).with(
            headers: sample_headers.merge(params[:headers]),
          ).to_return(
            status: 200,
            body: '{"status":"OK"}',
            headers: {
              'Content-Type' => 'application/json',
            },
          )

          resp = agent.send(:do_request, params[:url], params[:method], params[:headers], params[:data])
          expect(resp[:code]).to eq('200')
          expect(resp[:message]).to eq('')
          expect(resp[:headers]).to eq(
            'content-type' => ['application/json'],
          )
          expect(resp[:body]).to eq(
            {
              status: 'OK',
            }.to_json,
          )
        end
      end
    end
  end
end
