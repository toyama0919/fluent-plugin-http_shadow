# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.name          = "fluent-plugin-http_shadow"
  gem.version       = "0.1.0"
  gem.summary       = %q{copy http request. use shadow proxy server.}
  gem.description   = %q{copy http request. use shadow proxy server.}
  gem.license       = "MIT"
  gem.authors       = ["Hiroshi Toyama"]
  gem.email         = "toyama0919@gmail.com"
  gem.homepage      = "https://github.com/toyama0919/fluent-plugin-http_shadow"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_runtime_dependency "typhoeus"
  gem.add_runtime_dependency "addressable"
  gem.add_runtime_dependency "string-scrub" if RUBY_VERSION.to_f < 2.1
  gem.add_development_dependency 'bundler', '~> 1.7.2'
  gem.add_development_dependency 'fluentd', '~> 0.10.58'
  gem.add_development_dependency 'pry', '~> 0.10.1'
  gem.add_development_dependency 'rake', '~> 10.3.2'
  gem.add_development_dependency 'rubocop', '~> 0.24.1'
  gem.add_development_dependency 'rubygems-tasks', '~> 0.2'
  gem.add_development_dependency 'yard', '~> 0.8'
end
