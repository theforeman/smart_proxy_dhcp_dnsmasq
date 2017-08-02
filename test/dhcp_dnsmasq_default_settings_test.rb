require 'test_helper'
require 'smart_proxy_dhcp_dnsmasq/dhcp_dnsmasq_configuration'
require 'smart_proxy_dhcp_dnsmasq/dhcp_dnsmasq_plugin'

class DnsDnsmasqDefaultSettingsTest < Test::Unit::TestCase
  def test_default_settings
    Proxy::DHCP::Dnsmasq::Plugin.load_test_settings({})
    assert_equal '/etc/dnsmasq.conf', Proxy::DHCP::Dnsmasq::Plugin.settings.config
    assert_equal '/etc/dnsmasq.d/dhcp/', Proxy::DHCP::Dnsmasq::Plugin.settings.target_dir
    assert_equal '/var/lib/dnsmasq/dhcp.leases', Proxy::DHCP::Dnsmasq::Plugin.settings.lease_file
    assert_equal 'systemctl reload dnsmasq', Proxy::DHCP::Dnsmasq::Plugin.settings.reload_cmd
  end
end
