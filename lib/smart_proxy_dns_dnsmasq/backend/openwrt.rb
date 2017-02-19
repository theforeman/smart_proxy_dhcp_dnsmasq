require 'ipaddr'

module Proxy::Dns::Dnsmasq
  class Openwrt < ::Proxy::Dns::Dnsmasq::Record
    attr_reader :config_file, :reload_cmd, :dirty

    def initialize(config, reload_cmd, dns_ttl)
      @config_file = config
      @reload_cmd = reload_cmd
      @dirty = false

      super(dns_ttl)
    end

    def update!
      return unless @dirty
      @dirty = false

      File.write(@config_file, configuration.join('\n'))
      system(@reload_cmd)
    end

    def add_entry(type, fqdn, ip)
      raise Proxy::Dns::Error, "OpenWRT UCI can't manage IPv6 entries" if type == 'AAAA' || type == 'PTR' && IPAddr.new(ip).ipv6?
      return true if find_type(:domain, :name, fqdn)

      h = DSL::Config.new :domain
      h.options[:name] = fqdn
      h.options[:ip] = ip
      configuration << h
      @dirty = true
    end

    def remove_entry(type, fqdn = nil, ip = nil)
      raise Proxy::Dns::Error, "OpenWRT UCI can't manage IPv6 entries" if type == 'AAAA' || type == 'PTR' && IPAddr.new(ip).ipv6?
      return true unless h = find_type(:domain, fqdn && :name || :ip, fqdn || ip)

      configuration.delete h
      @dirty = true
    end

    def add_cname(name, canonical)
      return true if find_type(:cname, :name, name)

      c = DSL::Config.new :cname
      c.options[:cname] = name
      c.options[:target] = canonical
      configuration << c
      @dirty = true
    end

    def remove_cname(name)
      return true unless c = find_type(:cname, :name, name)

      configuration.delete c
      @dirty = true
    end

    private

    def find_type(filter_type, search_type, value)
      configuration.find do |config|
        next unless config.type == filter_type

        config.options.find do |name, opt|
          next unless name == search_type

          opt == value
        end
      end
    end

    def load!
      dsl = DSL.new(@configuration)
      dsl.instance_eval open(@config_file).read, @config_file
    end

    def configuration
      load! unless @configuration
      @configuration
    end

    class DSL
      class Config
        attr_reader :type, :name, :options

        def initialize(type, name = nil)
          @type = type.to_sym
          @name = name
          @options = {}
        end

        def to_s
          "config #{type} #{name}\n" + options.map do |name, value|
            if value.is_a? Array
              value.map do|val|
                "        list #{name} '#{val}'"
              end.join "\n"
            else
              "        config #{name} '#{value}'"
            end
          end.join("\n") + "\n\n"
        end
      end

      def initialize(config)
        @configs = config
      end

      def method_missing(m, *args)
        [m, args].flatten
      end

      def config(args)
        type, name = args
        @current_config = Config.new type, name
        @configs << @current_config 
      end

      def option(args)
        name, value = args

        @current_config.options[name] = value
      end

      def list(args)
        name, value = args

        @current_config.options[name] = [] unless @current_config.options[name]
        @current_config.options[name] << value
      end
    end
  end
end
