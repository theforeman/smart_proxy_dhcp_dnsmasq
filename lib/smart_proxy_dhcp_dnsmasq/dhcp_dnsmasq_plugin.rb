require 'smart_proxy_dhcp_dnsmasq/dhcp_dnsmasq_configuration'
require 'smart_proxy_dhcp_dnsmasq/dhcp_dnsmasq_version'

module Proxy::DHCP::Dnsmasq
  class Plugin < ::Proxy::Provider
    plugin :dhcp_dnsmasq, ::Proxy::DHCP::Dnsmasq::VERSION

    requires :dhcp, '>= 1.15'
    default_settings :config=> '/etc/dnsmasq.conf',
                     :target_dir => '/etc/dnsmasq.d/dhcp/',
                     :lease_file => '/var/lib/dnsmasq/dhcp.leases',
                     :reload_cmd => 'systemctl reload dnsmasq'

    validate_readable :lease_file

    load_classes ::Proxy::DHCP::Dnsmasq::PluginConfiguration
    load_dependency_injection_wirings ::Proxy::DHCP::Dnsmasq::PluginConfiguration
  end
end
