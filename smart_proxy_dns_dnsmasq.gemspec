require File.expand_path('../lib/smart_proxy_dns_dnsmasq/dns_dnsmasq_version', __FILE__)
require 'date'

Gem::Specification.new do |s|
  s.name        = 'smart_proxy_dns_dnsmasq'
  s.version     = Proxy::Dns::Dnsmasq::VERSION
  s.date        = Date.today.to_s
  s.license     = 'GPL-3.0'
  s.authors     = ['Alexander Olofsson']
  s.email       = ['alexander.olofsson@liu.se']
  s.homepage    = 'https://github.com/ace13/smart_proxy_dns_dnsmasq'

  s.summary     = "dnsmasq DNS provider plugin for Foreman's smart proxy"
  s.description = "dnamasq DNS provider plugin for Foreman's smart proxy"

  s.files       = Dir['{config,lib,bundler.d}/**/*'] + ['README.md', 'LICENSE']
  s.test_files  = Dir['test/**/*']

  s.add_development_dependency('rake')
  s.add_development_dependency('mocha')
  s.add_development_dependency('test-unit')
end
