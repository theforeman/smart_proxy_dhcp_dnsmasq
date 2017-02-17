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

      case backend
      when 'openwrt'
        container_instance.dependency :dns_provider, (lambda do
          ::Proxy::Dns::Dnsmasq::Backend::Openwrt.new(
              settings[:config_path],
              settings[:dnsmasq_name],
              settings[:dns_ttl]
        end)
      when 'default'
        container_instance.dependency :dns_provider, (lambda do
          ::Proxy::Dns::Dnsmasq::Backend::Default.new(
              settings[:config_path],
              settings[:dnsmasq_name],
              settings[:dns_ttl]
        end)
      end
    end
  end
end
