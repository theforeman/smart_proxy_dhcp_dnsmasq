require 'smart_proxy_dns_dnsmasq/dns_dnsmasq_version'
require 'smart_proxy_dns_dnsmasq/dns_dnsmasq_configuration'

module Proxy::Dns::Dnsmasq
  class Plugin < ::Proxy::Provider
    plugin :dns_dnsmasq, ::Proxy::Dns::Dnsmasq::VERSION

    # Settings listed under default_settings are required.
    # An exception will be raised if they are initialized with nil values.
    # Settings not listed under default_settings are considered optional and by default have nil value.
    default_settings :config_path => '/etc/dnsmasq.d/foreman.conf',
                     :reload_cmd => 'systemctl reload dnsmasq'

    requires :dns, '>= 1.15'

    # Verifies that a file exists and is readable.
    # Uninitialized optional settings will not trigger validation errors.
    validate_readable :config_path

    # Loads plugin files and dependencies
    load_classes ::Proxy::Dns::Dnsmasq::PluginConfiguration
    # Loads plugin dependency injection wirings
    load_dependency_injection_wirings ::Proxy::Dns::Dnsmasq::PluginConfiguration
  end
end
