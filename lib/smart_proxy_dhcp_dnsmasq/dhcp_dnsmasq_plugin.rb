module Proxy::DHCP::Dnsmasq
  class Plugin < ::Proxy::Provider
    plugin :dns_dnsmasq, ::Proxy::DHCP::Dnsmasq::VERSION

    requires :dns, '>= 1.15'
    default_settings :config_files => [ '/etc/dnsmasq.d/foreman.conf' ],
                     :reload_cmd => 'systemctl reload dnsmasq'

    load_classes ::Proxy::DHCP::Dnsmasq::PluginConfiguration
    load_dependency_injection_wirings ::Proxy::DHCP::Dnsmasq::PluginConfiguration
  end
end
