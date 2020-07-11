# frozen_string_literal: true

# MCollective Query agent
module MCollective::Agent
  require 'json'
  require 'uri'
  require 'net/http'

  # Query class
  class Query < MCollective::RPC::Agent
    action 'exporter' do
      begin
        resp = do_request(request[:url])
        reply[:metrics] = grep_metrics(resp[:body], request[:metrics])
      rescue StandardError => e
        reply.fail!(e.message)
      end
    end

    action 'rest' do
      begin
        resp = do_request(request[:url], request[:method], request[:headers], request[:data])
        reply[:code] = resp[:code]
        reply[:message] = resp[:message]
        reply[:body] = resp[:body]
        reply[:headers] = resp[:headers]
      rescue StandardError => e
        reply.fail!(e.message)
      end
    end

    # Filter out metrics requested
    def grep_metrics(content, metrics)
      found = {}
      content.each_line do |line|
        next if line.start_with?('#') || line.chomp.strip.empty?

        nl, value = line.split(' ')
        name, = nl.split('{')
        unless metrics.empty?
          next unless metrics.include?(name) || metrics.include?(nl)
        end
        found[nl.to_sym] = value
      end
      found
    end

    # Make HTTP request
    def do_request(url, method = 'GET', headers = {}, data = '')
      uri = URI.parse(url)
      # uri.user & uri.password & uri.scheme & uri.port

      # Stringify headers
      h = headers.respond_to?(:transform_keys) ? headers.transform_keys(&:to_s) : headers.map { |k, v| [k.to_s, v] }.to_h

      h['User-Agent'] = 'MCollective::Agent::Query' unless h['User-Agent']

      Net::HTTP.start(uri.host, uri.port) do |http|
        resp = http.send_request(method, uri, data, h)
        {
          code: resp.code,
          message: resp.message,
          body: resp.body,
          headers: resp.to_hash,
        }
      end
    end
  end
end
