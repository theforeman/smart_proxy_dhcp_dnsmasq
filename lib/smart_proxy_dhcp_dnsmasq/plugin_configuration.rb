# frozen_string_literal: true

module ::Proxy::DHCP::Dnsmasq
  class PluginConfiguration
    def load_classes
      require 'dhcp_common/free_ips'
      require 'smart_proxy_dhcp_dnsmasq/dhcp_dnsmasq_subnet_service'
      require 'smart_proxy_dhcp_dnsmasq/dhcp_dnsmasq_main'
    end

    def load_dependency_injection_wirings(container, settings)
      container.singleton_dependency :unused_ips, -> { ::Proxy::DHCP::FreeIps.new(settings[:blacklist_duration_minutes]) }

      container.dependency :memory_store, ::Proxy::MemoryStore

      container.singleton_dependency :subnet_service, (lambda do
        ::Proxy::DHCP::Dnsmasq::SubnetService.new(
          settings[:config], settings[:target_dir], settings[:lease_file],
          container.get_dependency(:memory_store),
          container.get_dependency(:memory_store), container.get_dependency(:memory_store),
          container.get_dependency(:memory_store), container.get_dependency(:memory_store)
        )
      end)
      container.dependency :dhcp_provider, (lambda do
        Proxy::DHCP::Dnsmasq::Provider.new(
          settings[:target_dir],
          settings[:reload_cmd], container.get_dependency(:subnet_service),
          container.get_dependency(:unused_ips)
        )
      end)
    end
  end
end
