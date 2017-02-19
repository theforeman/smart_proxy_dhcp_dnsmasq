require 'dns_common/dns_common'
require 'ipaddr'

module Proxy::Dns::Dnsmasq
  class Record < ::Proxy::Dns::Record
    include Proxy::Log

    def initialize(dns_ttl)
      super('localhost', dns_ttl)
    end

    def do_create(name, value, type)
      case type
      when 'A', 'AAAA'
        add_entry(type, name, value)
      when 'PTR'
        add_entry(type, value, ptr_to_ip(name))
      when 'CNAME'
        add_cname(name, value)
      else
        raise Proxy::Dns::Error, "Can't create entries of type #{type}"
      end

      update!
    end

    def do_remove(name, type)
      case type
      when 'A', 'AAAA'
        remove_entry(type, name)
      when 'PTR'
        remove_entry(type, nil, ptr_to_ip(name))
      when 'CNAME'
        remove_cname(name)
      else
        raise Proxy::Dns::Error, "Can't remove entries of type #{type}"
      end

      update!
    end
  end
end
