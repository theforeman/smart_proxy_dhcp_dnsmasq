require 'smart_proxy_dns_plugin_template/dns_plugin_template_version'

module Proxy::Dns::PluginTemplate
  class Plugin < ::Proxy::Provider
    plugin :dns_plugin_template, ::Proxy::Dns::PluginTemplate::VERSION

    # Settings listed under default_settings are required.
    # An exception will be raised if they are initialized with nil values.
    # Settings not listed under default_settings are considered optional and by default have nil value.
    default_settings :required_setting => 'default_value', :required_path => '/must/exist'

    requires :dns, '>= 1.15'

    # Verifies that a file exists and is readable.
    # Uninitialized optional settings will not trigger validation errors.
    validate_readable :required_path, :optional_path

    # Loads plugin files and dependencies
    load_classes ::Proxy::Dns::PluginTemplate::PluginConfiguration
    # Loads plugin dependency injection wirings
    load_dependency_injection_wirings ::Proxy::Dns::PluginTemplate::PluginConfiguration
  end
end
