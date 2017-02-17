module Proxy::Dns::Dnsmasq::Backend
  class Openwrt < ::Proxy::Dns::Dnsmasq::Record
    def initialize(config, process_name, dns_ttl)
      @config_file = config
      @process_name = process_name
      @dirty = false

      super(dns_ttl)
    end

    def update!
      return unless @dirty
      @dirty = false

      File.write(@config_file, @configuration.join '\n')
      system("killall -s SIGHUP #{process_name}")
    end

    def add_cname(name, canonical)
      c = find_type(:cname, :name, name)
      return true if c

      @dirty = true
      c = DSL::Config.new :cname
      c.options[:cname] = name
      c.options[:target] = canonical
      configuration << c
    end

    def remove_cname(name)
      c = find_type(:cname, :name, name)
      return true unless c

      @dirty = true
      configuration.delete c
    end

    def add_host(fqdn = nil, ip = nil)
      h = find_type(:domain, fqdn && :name || :ip, fqdn || ip)
      return true if h

      @dirty = true
      h = DSL::Config.new :domain
      h.options[:name] = fqdn
      h.options[:ip] = ip
      configuration << h
    end

    def remove_host(fqdn = nil, ip = nil)
      h = find_type(:domain, fqdn && :name || :ip, fqdn || ip)
      return true unless h

      @dirty = true
      configuration.delete h
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

    def load
      dsl = DSL.new(@configuration)
      dsl.instance_eval open(@config_file).read, @config_file
      true
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
              value.map do|value|
                "        list #{name} '#{value}'"
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
