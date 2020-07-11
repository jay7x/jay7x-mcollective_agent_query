metadata :name => 'query',
         :description => 'Query data from various HTTP endpoints',
         :author => 'Yury Bushmelev <jay4mail@gmail.com>',
         :license => 'Apache-2.0',
         :version => '1.0.0',
         :url => 'https://github.com/jay7x/jay7x-mcollective_agent_query',
         :timeout => 60

action 'exporter', :description => 'Returns Prometheus exporter metrics requested' do
  display :always

  input :url,
        :prompt => 'URL',
        :description => 'Prometheus exporter URL to query',
        :type => :string,
        :validation => '.*',
        :maxlength => 64 * 1024,
        :optional => false

  input :metrics,
        :prompt => 'Metrics',
        :description => 'Metrics to return from URL',
        :type => :array,
        :default => [],
        :optional => true

  output :metrics,
         :description => 'Metrics returned',
         :display_as => 'Metrics',
         :type => :hash,
         :default => {}
end

action 'rest', :description => 'Returns REST API reply' do
  display :always

  input :url,
        :prompt => 'URL',
        :description => 'API URL to query',
        :type => :string,
        :validation => '.*',
        :maxlength => 10 * 1024,
        :optional => false

  input :method,
        :prompt => 'Method',
        :description => 'HTTP method to use',
        :type => :list,
        :list => ['GET','POST','PUT','DELETE','HEAD','LIST'],
        :default => 'GET',
        :optional => true

  input :headers,
        :prompt => 'Headers',
        :description => 'HTTP headers to send',
        :type => :hash,
        :default => {},
        :optional => true

  input :data,
        :prompt => 'Data',
        :description => 'HTTP data to send',
        :type => :string,
        :validation => '.*',
        :maxlength => 64 * 1024,
        :default => '',
        :optional => true

  output :code,
         :description => 'HTTP Status code',
         :display_as => 'Code',
         :type => :string,
         :default => ''

  output :message,
         :description => 'HTTP reply message',
         :display_as => 'Message',
         :type => :string,
         :default => ''

  output :body,
         :description => 'HTTP reply body',
         :display_as => 'Body',
         :type => :string,
         :default => ''

  output :headers,
         :description => 'HTTP reply headers',
         :display_as => 'Headers',
         :type => :hash,
         :default => {}
end
