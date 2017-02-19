module Proxy::DHCP::Dnsmasq
  class Plugin < ::Proxy::Provider
    plugin :dns_dnsmasq, ::Proxy::DHCP::Dnsmasq::VERSION

    requires :dns, '>= 1.15'
    default_settings :config_file => '/etc/dnsmasq.d/foreman.conf',
                     :lease_file => '/tmp/dhcp.leases',
                     :reload_cmd => 'systemctl reload dnsmasq'

    validate_readable :config_file, :lease_file

    load_classes ::Proxy::DHCP::Dnsmasq::PluginConfiguration
    load_dependency_injection_wirings ::Proxy::DHCP::Dnsmasq::PluginConfiguration
  end
end
