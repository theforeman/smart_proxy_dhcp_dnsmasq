module ::Proxy::DHCP::Dnsmasq
  class PluginConfiguration
    def load_classes
      require 'smart_proxy_dhcp_dnsmasq/dhcp_dnsmasq_subnet_service'
      require 'smart_proxy_dhcp_dnsmasq/dhcp_dnsmasq_main'
    end

    def load_dependency_injection_wirings(container, settings)
      container.dependency :memory_store, ::Proxy::MemoryStore
      container.dependency :subnet_service, (lambda do
        ::Proxy::DHCP::Dnsmasq::SubnetService.new(settings[:config_dir], settings[:lease_file],
          container.get_dependency(:memory_store),
          container.get_dependency(:memory_store), container.get_dependency(:memory_store),
          container.get_dependency(:memory_store), container.get_dependency(:memory_store))
      end)
      container.dependency :dhcp_provider, (lambda do
        Proxy::DHCP::Dnsmasq::Record.new(settings[:write_config_dir], settings[:config_dir], settings[:reload_cmd], container.get_dependency(:subnet_service))
      end)
    end
  end
end
