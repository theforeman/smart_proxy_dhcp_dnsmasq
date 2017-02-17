require 'dns_common/dns_common'
require 'ipaddr'

module Proxy::Dns::Dnsmasq
  class Record < ::Proxy::Dns::Record
    include Proxy::Log

    def initialize(dns_ttl)
      super('localhost', dns_ttl)
    end

    def do_create(name, value, type)
      raise Proxy::Dns::Error.new("Failed to point #{name} to #{value} with type #{type}") unless case type
      when 'A'
        add_host(name, value)
      when 'PTR'
        ip = ptr_to_ip(name)
        raise Proxy::Dns::Error.new("Can't create IPV6 PTR records.") if IPAddr.new(ip).ipv6?

        add_host(value, name)
      when 'CNAME'
        add_cname(name, value)
      end
    end

    def do_remove(name, type)
      raise Proxy::Dns::Error.new("Failed to remove #{name} of type #{type}") unless case type
      when 'A'
        add_host(name, value)
      when 'PTR'
        ip = ptr_to_ip(name)
        raise Proxy::Dns::Error.new("Can't remove IPV6 PTR records.") if IPAddr.new(ip).ipv6?

        add_host(value, ip)
      when 'CNAME'
        add_cname(name, value)
      end
    end
  end
end
