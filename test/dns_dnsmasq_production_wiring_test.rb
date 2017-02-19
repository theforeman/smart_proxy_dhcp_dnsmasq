require 'test_helper'
require 'smart_proxy_dns_dnsmasq/dns_dnsmasq_configuration'
require 'smart_proxy_dns_dnsmasq/dns_dnsmasq_main'

class DnsDnsmasqProductionWiringTest < Test::Unit::TestCase
  def setup
    @container = ::Proxy::DependencyInjection::Container.new
    @config = ::Proxy::Dns::Dnsmasq::PluginConfiguration.new
  end

  def test_dns_provider_initialization_default
    @config.load_dependency_injection_wirings(@container, :dns_ttl => 999,
                                              :config_path => '/etc/dnsmasq.conf',
                                              :reload_cmd => 'systemctl reload dnsmasq')

    provider = @container.get_dependency(:dns_provider)

    assert_not_nil provider
    assert_equal provider.class, Proxy::Dns::Dnsmasq::Default
    assert_equal '/etc/dnsmasq.conf', provider.config_file
    assert_equal 'systemctl reload dnsmasq', provider.reload_cmd
    assert_equal 999, provider.ttl
  end

  def test_dns_provider_initialization
    @config.load_dependency_injection_wirings(@container, :dns_ttl => 999,
                                              :backend => 'openwrt',
                                              :config_path => '/etc/config/dhcp',
                                              :reload_cmd => '/etc/init.d/dnsmasq reload')

    provider = @container.get_dependency(:dns_provider)

    assert_not_nil provider
    assert_equal provider.class, Proxy::Dns::Dnsmasq::Openwrt
    assert_equal '/etc/config/dhcp', provider.config_file
    assert_equal '/etc/init.d/dnsmasq reload', provider.reload_cmd
    assert_equal 999, provider.ttl
  end
end
