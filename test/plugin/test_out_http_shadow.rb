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
end


