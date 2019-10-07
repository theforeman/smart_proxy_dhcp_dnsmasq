# frozen_string_literal: true

require 'smart_proxy_dhcp_dnsmasq/dhcp_dnsmasq_version'
require 'smart_proxy_dhcp_dnsmasq/plugin_configuration'

module Proxy::DHCP::Dnsmasq
  class Plugin < ::Proxy::Provider
    plugin :dhcp_dnsmasq, ::Proxy::DHCP::Dnsmasq::VERSION

    requires :dhcp, '>= 1.17'
    default_settings :config=> '/etc/dnsmasq.conf',
                     :target_dir => '/var/lib/foreman-proxy/dhcp/',
                     :lease_file => '/var/lib/dnsmasq/dhcp.leases',
                     :reload_cmd => 'systemctl reload dnsmasq'

    validate_readable :lease_file

    load_classes ::Proxy::DHCP::Dnsmasq::PluginConfiguration
    load_dependency_injection_wirings ::Proxy::DHCP::Dnsmasq::PluginConfiguration

    start_services :unused_ips, :subnet_service
  end
end
