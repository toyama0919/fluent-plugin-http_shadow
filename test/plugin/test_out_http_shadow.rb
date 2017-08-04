require 'helper'
class HttpShadowOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  def create_driver(conf = CONFIG, tag = 'test')
    Fluent::Test::BufferedOutputTestDriver.new(Fluent::HttpShadowOutput, tag).configure(conf)
  end

  def test_configure
    d = create_driver %[
      host google.com
      path_format ${path}
      method_key method
      path_format ${url}
      method_key method
      header_hash { "Referer": "${referer}", "X-Forwarded-For": "${ip_address}" }
      cookie_hash { "iij-stg1_session": "${session_id}", "___IPROS_UUID_": "${uuid}"}
      flush_interval 10
    ]
    assert_equal 'google.com', d.instance.host
    assert_equal 'method', d.instance.method_key
    assert_equal '${url}', d.instance.path_format
  end

  def test_configure_error
    assert_raise(Fluent::ConfigError) do
      d = create_driver %[
        path_format ${path}
        method_key method
        path_format ${url}
        method_key method
        header_hash { "Referer": "${referer}", "X-Forwarded-For": "${ip_address}" }
        cookie_hash { "iij-stg1_session": "${session_id}", "___IPROS_UUID_": "${uuid}"}
        flush_interval 10
      ]
    end
  end

  def test_get_cookie_string
    d = create_driver %[
      host google.com
      path_format ${path}
      method_key method
      path_format ${url}
      method_key method
      header_hash { "Referer": "${referer}", "X-Forwarded-For": "${ip_address}" }
      cookie_hash { "cookie1": "${cookie1}", "cookie2": "${cookie2}"}
      flush_interval 10
    ]
    d.instance.start
    cookie_string = d.instance.send(:get_cookie_string, { 'cookie1' => 'value1'})
    assert_equal cookie_string, "cookie1=value1; cookie2="

    cookie_string = d.instance.send(:get_cookie_string, { 'cookie1' => 'value1', 'cookie2' => 'value2' })
    assert_equal cookie_string, "cookie1=value1; cookie2=value2"
  end

  def test_get_cookie_string_no_send_header_pattern
    d = create_driver %[
      host google.com
      path_format ${path}
      method_key method
      path_format ${url}
      method_key method
      header_hash { "Referer": "${referer}", "X-Forwarded-For": "${ip_address}" }
      cookie_hash { "cookie1": "${cookie1}", "cookie2": "${cookie2}", "cookie3": "${cookie3}" }
      no_send_header_pattern ^(-|)$
      flush_interval 10
    ]
    d.instance.start

    cookie_string = d.instance.send(:get_cookie_string, { 'cookie1' => '-', 'cookie2' => '', 'cookie3' => 'value3' })
    assert_equal cookie_string, "cookie3=value3"

    cookie_string = d.instance.send(:get_cookie_string, { 'cookie1' => '-', 'cookie2' => '', 'cookie3' => '' })
    assert_equal cookie_string, ""
  end

  def test_get_header
    d = create_driver %[
      host google.com
      path_format ${path}
      method_key method
      path_format ${url}
      method_key method
      header_hash { "Referer": "${referer}?hub=param", "X-Forwarded-For": "${ip_address}", "User-Agent": "${user_agent}" }
      cookie_hash { "cookie1": "${cookie1}"}
      flush_interval 10
    ]
    d.instance.start
    header = d.instance.send(
      :get_header,
      {
        'referer' => 'http://eetimes.jp/ee/articles/1407/30/news071.html',
        'ip_address' => '10.10.10.10',
        'user_agent' => 'Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.124 Safari/537.36',
        'cookie1' => 'value1'
      }
    )
    assert_equal header['Referer'], "http://eetimes.jp/ee/articles/1407/30/news071.html?hub=param"
    assert_equal header['X-Forwarded-For'], "10.10.10.10"
    assert_equal header['User-Agent'], "Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.124 Safari/537.36"
    assert_equal header['Cookie'], "cookie1=value1"
  end

  def test_get_header_no_send_header_pattern
    d = create_driver %[
      host google.com
      path_format ${path}
      method_key method
      path_format ${url}
      method_key method
      header_hash { "Referer": "${referer}", "X-Forwarded-For": "${ip_address}", "User-Agent": "${user_agent}" }
      cookie_hash { "cookie1": "${cookie1}"}
      no_send_header_pattern ^(-|)$
      flush_interval 10
    ]
    d.instance.start
    header = d.instance.send(
      :get_header,
      {
        'referer' => '-',
        'ip_address' => '10.10.10.10',
        'user_agent' => '',
        'cookie1' => 'value1'
      }
    )
    assert_equal header['Referer'], nil
    assert_equal header['X-Forwarded-For'], "10.10.10.10"
    assert_equal header['User-Agent'], nil
    assert_equal header['Cookie'], "cookie1=value1"
  end

  def test_supported?
    d = create_driver %[
      host google.com
      path_format ${path}
      method_key method
      path_format ${url}
      method_key method
      header_hash { "Referer": "${referer}", "X-Forwarded-For": "${ip_address}" }
      cookie_hash { "iij-stg1_session": "${session_id}", "___IPROS_UUID_": "${uuid}"}
      flush_interval 10
      support_methods [ "get", "post" ]
    ]
    d.instance.start
    assert_true d.instance.send(:supported?, :get)
    assert_true d.instance.send(:supported?, :post)
    assert_false d.instance.send(:supported?, :put)
  end

  def test_rate_per_method
    d = create_driver %[
      host google.com
      path_format ${path}
      method_key method
      path_format ${url}
      method_key method
      header_hash { "Referer": "${referer}", "X-Forwarded-For": "${ip_address}" }
      cookie_hash { "iij-stg1_session": "${session_id}", "___IPROS_UUID_": "${uuid}"}
      flush_interval 10
      rate_per_method_hash { "get": 100, "post": 0 }
    ]
    d.instance.start
    assert_true d.instance.send(:rate_per_method, :get)
    assert_false d.instance.send(:rate_per_method, :post)
    assert_true d.instance.send(:rate_per_method, :put)
  end
end


