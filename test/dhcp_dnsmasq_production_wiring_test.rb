require 'test_helper'
require 'smart_proxy_dhcp_dnsmasq/dhcp_dnsmasq_configuration'
require 'smart_proxy_dhcp_dnsmasq/dhcp_dnsmasq_main'

class DHCPDnsmasqProductionWiringTest < Test::Unit::TestCase
  def setup
    @container = ::Proxy::DependencyInjection::Container.new
    @config = ::Proxy::DHCP::Dnsmasq::PluginConfiguration.new
  end

  def test_dns_provider_initialization_default
    Proxy::DHCP::Dnsmasq::SubnetService.any_instance.expects(:load!).returns(true)
    Dir.expects(:exist?).with('/etc/dnsmasq.d/dhcp').returns(true)

    @config.load_dependency_injection_wirings(
      @container,
      :config => '/etc/dnsmasq.conf',
      :target_dir => '/etc/dnsmasq.d/dhcp',
      :lease_file => '/tmp/dhcp.leases',
      :reload_cmd => 'systemctl reload dnsmasq'
    )

    provider = @container.get_dependency(:dhcp_provider)

    assert_not_nil provider
    assert_equal '/etc/dnsmasq.d/dhcp', provider.config_dir
    assert_equal 'systemctl reload dnsmasq', provider.reload_cmd
  end
end
