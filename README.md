# fluent-plugin-http_shadow [![Build Status](https://secure.travis-ci.org/toyama0919/fluent-plugin-http_shadow.png?branch=master)](http://travis-ci.org/toyama0919/fluent-plugin-http_shadow)

copy http request. use shadow proxy server.

![Qiita](https://embed.gyazo.com/59d5fe9c4430325f6ad59c638971cc25.png "Qiita")

restored the http request from the logs that are sent to the fluentd.

## Examples
```
<source>
  type tail
  format apache
  path /var/log/httpd/access_log
  pos_file /var/log/td-agent/access.pos
  tag apache.access
</source>

<match apache.access>
  type http_shadow
  host staging.exsample.com
  path_format ${path}
  method_key method
  header_hash { "Referer": "${referer}", "User-Agent": "${agent}" }
</match>
```

Assume following input is coming:

```
  {
    "host": "exsample.com",
    "ip_address": "127.0.0.1",
    "server": "10.0.0.11",
    "remote": "-",
    "time": "22/Dec/2014:03:20:26 +0900",
    "method": "GET",
    "path": "/hoge/?id=1",
    "code": "200",
    "size": "1578",
    "x_forwarded_proto": "http",
    "referer": "http://exsample.com/other/",
    "agent": "Mozilla/5.0 (Windows NT 6.1; Trident/7.0; rv:11.0) like Gecko"
  }
```

then result becomes as below (indented):

```
GET http://staging.exsample.com/hoge/?id=1
#=>  HTTP HEADER
#=>  "referer": "http://exsample.com/other/"
#=>  "agent": "Mozilla/5.0 (Windows NT 6.1; Trident/7.0; rv:11.0) like Gecko"
```

## Examples(Virtual Host)
```
<match http_shadow.exsample>
  type http_shadow
  host_hash { 
    "www.example.com": "staging.example.com", 
    "api.example.com": "api-staging.example.com", 
    "blog.ipros.jp": "blog-staging.ipros.jp"
  }
  host_key host
  path_format ${path}
  method_key method
  protocol_format ${x_forwarded_proto} # default: http
  header_hash { "Referer": "${referer}", "User-Agent": "${user_agent}" }
  no_send_header_pattern ^(-|)$
</match>
```

## Examples(use cookie)
```
<match http_shadow.exsample>
  type http_shadow
  host_hash { 
    "www.example.com": "staging.example.com", 
    "api.example.com": "api-staging.example.com", 
    "blog.ipros.jp": "blog-staging.ipros.jp"
  }
  host_key host
  path_format ${path}
  method_key method
  header_hash { "Referer": "${referer}", "User-Agent": "${user_agent}" }
  cookie_hash {"rails-app_session": "${session_id}"}
</match>
```

## Examples(use rate_per_method_hash)
```
<match http_shadow.exsample>
  type http_shadow
  host_hash {
    "www.example.com": "staging.example.com",
    "api.example.com": "api-staging.example.com",
    "blog.ipros.jp": "blog-staging.ipros.jp"
  }
  host_key host
  path_format ${path}
  method_key method
  header_hash { "Referer": "${referer}", "User-Agent": "${user_agent}" }
  rate_per_method_hash {
    "get": 30, # This means 30% requests of GET will be sent. Default(when not defined) value is 100.
    "post": 90
  }
</match>
```

## Examples(use support_methods)
```
<match http_shadow.exsample>
  type http_shadow
  host_hash {
    "www.example.com": "staging.example.com",
    "api.example.com": "api-staging.example.com",
    "blog.ipros.jp": "blog-staging.ipros.jp"
  }
  host_key host
  path_format ${path}
  method_key method
  header_hash { "Referer": "${referer}", "User-Agent": "${user_agent}" }
  support_methods [ "get", "post" ] # It means that only GET and POST are sent. By default all methods are sent.
</match>
```

## note

default GET Request.

## parameter

TODO

## todo

more test


## Installation
```
fluent-gem install fluent-plugin-http_shadow
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new [Pull Request](../../pull/new/master)

## Information

* [Homepage](https://github.com/toyama0919/fluent-plugin-http_shadow)
* [Issues](https://github.com/toyama0919/fluent-plugin-http_shadow/issues)
* [Documentation](http://rubydoc.info/gems/fluent-plugin-http_shadow/frames)
* [Email](mailto:toyama0919@gmail.com)

## Copyright

Copyright (c) 2015 Hiroshi Toyama

