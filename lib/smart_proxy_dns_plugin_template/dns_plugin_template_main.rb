require 'dns_common/dns_common'

module Proxy::Dns::PluginTemplate
  class Record < ::Proxy::Dns::Record
    include Proxy::Log

    attr_reader :example_setting, :optional_path, :required_setting, :required_path

    def initialize(required_setting, example_setting, required_path, optional_path, dns_ttl)
      @required_setting = required_setting # never nil
      @example_setting = example_setting # can be nil
      @required_path = required_path # file exists and is readable
      @optional_path = optional_path # nil, or file exists and is readable

      # Common settings can be defined by the main plugin, it's ok to use them locally.
      # Please note that providers must not rely on settings defined by other providers or plugins they are not related to.
      super('localhost', dns_ttl)
    end

    # Calls to these methods are guaranteed to have non-nil parameters
    def create_a_record(fqdn, ip)
      case a_record_conflicts(fqdn, ip) #returns -1, 0, 1
        when 1
          raise(Proxy::Dns::Collision, "'#{fqdn} 'is already in use")
        when 0 then
          return nil
        else
          # FIXME: add a forward 'A' record with fqdn, ip
      end
    end

    def create_aaaa_record(fqdn, ip)
      case aaaa_record_conflicts(fqdn, ip) #returns -1, 0, 1
        when 1
          raise(Proxy::Dns::Collision, "'#{fqdn} 'is already in use")
        when 0 then
          return nil
        else
          # FIXME: add a forward 'AAAA' record with fqdn, ip
      end
    end

    def create_ptr_record(fqdn, ptr)
      case ptr_record_conflicts(fqdn, ptr_to_ip(ptr)) #returns -1, 0, 1
        when 1
          raise(Proxy::Dns::Collision, "'#{fqdn} 'is already in use")
        when 0 then
          return nil
        else
          # FIXME: add a reverse 'PTR' record with ip, fqdn
      end
    end

    def remove_a_record(fqdn)
      raise Proxy::Dns::NotFound.new("Cannot find DNS entry for #{fqdn}") unless dns_find(fqdn)
      # FIXME: remove the forward 'A' record with fqdn
    end

    def remove_aaaa_record(fqdn)
      raise Proxy::Dns::NotFound.new("Cannot find DNS entry for #{fqdn}") unless dns_find(fqdn)
      # FIXME: remove the forward 'AAAA' record with fqdn
    end

    def remove_ptr_record(ip)
      raise Proxy::Dns::NotFound.new("Cannot find DNS entry for #{ip}") unless dns_find(ip)
      # FIXME: remove the reverse 'PTR' record with ip
    end
  end
end
