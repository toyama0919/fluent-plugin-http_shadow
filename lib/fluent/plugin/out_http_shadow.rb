require 'json'
module Fluent
  class HttpShadowOutput < Fluent::Output
    Fluent::Plugin.register_output('http_shadow', self)

    def initialize
      super
      require 'uri'
      require 'net/http'
      require 'erb'
    end

    config_param :host, :string, :default => nil
    config_param :host_key, :string, :default => nil
    config_param :host_hash, :hash, :default => nil
    config_param :path_format, :string
    config_param :method_key, :string
    config_param :header_hash, :hash, :default => nil
    config_param :cookie_hash, :hash, :default => nil
    config_param :params_key, :string, :default => nil

    def configure(conf)
      super
      if host
        @http = Net::HTTP.new(host)
      else
        @host_hash = Hash[@host_hash.map { |k,v| [k, Net::HTTP.new(v)] }]
      end
      @regexp = /\$\{([^}]+)\}/
      @path_format = @path_format.gsub(@regexp, "<%=record['" + '\1' + "'] %>")
      @path_format = ERB.new(@path_format)

      @headers = get_formatter(@header_hash)
      @cookies = get_formatter(@cookie_hash)
    end

    def start
      super
    end

    def shutdown
      super
    end

    def emit(tag, es, chain)
      chain.next
      es.each {|time,record|
        http = @http || @host_hash[record[@host_key]]
        next if http.nil?
        send_request(http, record)
      }
    end

    def send_request(http, record)
      method = record[@method_key] || 'GET'

      path = @path_format.result(binding)
      params = record[@params_key]
      unless params.nil?
        path = add_query_string(path, record, params) if method !~ /POST/i
      end
      req = Net::HTTP.const_get(method.capitalize).new(path)
      unless params.nil?
        req.set_form_data(params, "&") if method =~ /POST/i
      end
      req = set_header(req, record)
      req['Cookie'] = get_cookie_string(record) if @cookie_hash
      response = http.request(req)
    end

    def add_query_string(path, record, params)
      uri = URI.parse(path)
      params_string = params.collect { |k,v| "#{k}=#{CGI::escape(v.to_s)}" }.join('&')
      join_string = uri.query.nil? ? '?' : '&'
      path = path + join_string + params_string
      path
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

    def set_header(req, record)
      @headers.each do |k, v|
        req[k] = v.result(binding)
      end
      req
    end

    def get_cookie_string(record)
      @cookies.map{|k, v|
        "#{k}=#{v.result(binding)}"
      }.join(';')
    end
  end
end
