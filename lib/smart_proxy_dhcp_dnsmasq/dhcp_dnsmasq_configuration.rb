module ::Proxy::DHCP::Dnsmasq
  class PluginConfiguration
    def load_classes
      require 'dhcp_common/subnet_service'
      require 'dhcp_common/server'
      require 'smart_proxy_dhcp_dnsmasq/dhcp_dnsmasq_subnet_service'
      require 'smart_proxy_dhcp_dnsmasq/dhcp_dnsmasq_main'
    end

    def load_dependency_injection_wirings(container_instance, settings)
      write_config = settings[:write_config_file] || settings[:config_files].last

      container.dependency :memory_store, ::Proxy::MemoryStore
      container.dependency :subnet_service, (lambda do
        ::Proxy::DHCP::Dnsmasq::SubnetService.new(settings[:config_files], settings[:lease_file],
          container.get_dependency(:memory_store),
          container.get_dependency(:memory_store), container.get_dependency(:memory_store),
          container.get_dependency(:memory_store), container.get_dependency(:memory_store))
      end)
      container.dependency :dhcp_provider, (lambda do
        Proxy::DHCP::Dnsmasq::Provider.new(write_config, settings[:reload_cmd], container.get_dependency(:subnet_service))
      end)
    end
  end
end
