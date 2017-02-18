module ::Proxy::Dns::Dnsmasq
  class PluginConfiguration
    def load_classes
      require 'dns_common/dns_common'
      require 'smart_proxy_dns_dnsmasq/dns_dnsmasq_main'
    end

    def load_dependency_injection_wirings(container_instance, settings)
      BACKENDS = [ 'openwrt', 'default' ].freeze
      backend = settings[:backend] || 'default'

      unless BACKENDS.include? backend
        raise ::Proxy::Error::ConfigurationError, 'In'
      end

      require "smart_proxy_dns_dnsmasq/backend/#{backend}"

      klass = case backend
      when 'openwrt'
        ::Proxy::Dns::Dnsmasq::Backend::Openwrt
      when 'default'
        ::Proxy::Dns::Dnsmasq::Backend::Default
      end
      container_instance.dependency :dns_provider, (lambda do
        klass.new(
            settings[:config_path],
            settings[:reload_cmd],
            settings[:dns_ttl]
      end)
    end
  end
end
