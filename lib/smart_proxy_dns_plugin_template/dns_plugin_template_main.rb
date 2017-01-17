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

    def do_create(name, value, type)
      # FIXME: There is no trailing dot. Your backend might require it.
      if false
        name += '.'
        value += '.' if ['PTR', 'CNAME'].include?(type)
      end

      # FIXME: Create a record with the correct name, value and type
      raise Proxy::Dns::Error.new("Failed to point #{name} to #{value} with type #{type}")
    end

    def do_remove(name, type)
      # FIXME: There is no trailing dot. Your backend might require it.
      if false
        name += '.'
      end

      # FIXME: Remove a record with the correct name and type
      raise Proxy::Dns::Error.new("Failed to remove #{name} of type #{type}")
    end
  end
end
