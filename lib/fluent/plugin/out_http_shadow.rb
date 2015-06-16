module Fluent
  class HttpShadowOutput < Fluent::BufferedOutput
    Fluent::Plugin.register_output('http_shadow', self)

    def initialize
      super
      require 'erb'
      require 'typhoeus'
      require "addressable/uri"
    end

    config_param :host, :string, :default => nil
    config_param :host_key, :string, :default => nil
    config_param :host_hash, :hash, :default => nil
    config_param :path_format, :string
    config_param :method_key, :string, :default => nil
    config_param :header_hash, :hash, :default => nil
    config_param :cookie_hash, :hash, :default => nil
    config_param :params_key, :string, :default => nil
    config_param :max_concurrency, :integer, :default => 10
    config_param :timeout, :integer, :default => 5
    config_param :username, :string, :default => nil
    config_param :password, :string, :default => nil
    config_param :rate, :integer, :default => 100
    config_param :replace_hash, :hash, :default => nil

    def configure(conf)
      super
      if @host.nil? && @host_hash.nil?
        raise ConfigError, "out_http_shadow: required to @host or @host_hash."
      end
    end

    def start
      super
      @regexp = /\$\{([^}]+)\}/
      @path_format = ERB.new(@path_format.gsub(@regexp, "<%=record['" + '\1' + "'] %>"))

      @headers = get_formatter(@header_hash)
      @cookies = get_formatter(@cookie_hash)
    end

    def shutdown
      super
    end

    def format(tag, time, record)
      [tag, time, record].to_msgpack
    end

    def write(chunk)
      records = []
      chunk.msgpack_each do |tag, time, record|
        records << record
      end
      sampling_size = (records.size * (@rate * 0.01)).to_i
      if @rate > 100
        orig_records = records.dup
        loop do
          records.concat(orig_records)
          break if sampling_size < records.size
        end
      end
      send_request_parallel(records.first(sampling_size))
    end

    private

    def send_request_parallel(records)
      hydra = Typhoeus::Hydra.new(max_concurrency: @max_concurrency)
      records.each do |record|
        host = @host || @host_hash[record[@host_key]]
        next if host.nil?
        hydra.queue(get_request(host, record))
      end
      hydra.run
    end

    def get_request(host, record)
      method = (record[@method_key] || 'get').downcase.to_sym
      path = @path_format.result(binding)
      path = replace_string(path) if @replace_hash

      url = "http://" + host + path
      uri = Addressable::URI.parse(url)
      params = uri.query_values
      params.merge(record[@params_key]) unless record[@params_key].nil?
      params = replace_params(params) if @replace_hash && params

      option = {
        timeout: @timeout,
        followlocation: true,
        method: method,
        params: params,
        headers: get_header(record)
      }
      option[:userpwd] = "#{@username}:#{@password}" if @username

      Typhoeus::Request.new("http://" + host + uri.path, option)
    end

    def get_formatter(hash)
      formatter = {}
      return formatter unless hash
      hash.each do |k, v|
        format = v.gsub(@regexp,  "<%=record['" + '\1' + "'] %>")
        formatter[k] = ERB.new(format)
      end
      formatter
    end

    def get_header(record)
      header = {}
      @headers.each do |k, v|
        header[k] = v.result(binding)
      end
      header['Cookie'] = get_cookie_string(record) if @cookie_hash
      header
    end

    def replace_string(str)
      return nil if str.nil?
      @replace_hash.each do |k, v|
        str = str.gsub(k, v)
      end
      str
    end

    def replace_params(params)
      Hash[params.map { |k,v| [k, replace_string(v)] }]
    end

    def get_cookie_string(record)
      @cookies.map{|k, v|
        "#{k}=#{v.result(binding)}"
      }.join('; ')
    end
  end
end
