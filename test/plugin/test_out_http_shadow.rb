require 'helper'
class HttpShadowOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    host staging.exsample.com
    path_format ${path}
    method_key method
  ]

  def create_driver(conf = CONFIG, tag='test')
    Fluent::Test::OutputTestDriver.new(Fluent::HttpShadowOutput, tag).configure(conf)
  end

  def test_configure
    d = create_driver
    assert_equal 'method', d.instance.method_key
    assert_equal nil, d.instance.header_hash
  end

  def test_configure_error
    config = %[
      method_key method
    ]
    assert_raise(Fluent::ConfigError) do
      d = create_driver(config)
    end
  end

end
