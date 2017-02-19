module Proxy::Dns::Dnsmasq
  class Default < ::Proxy::Dns::Dnsmasq::Record
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

      File.write(@config_file, configuration.join("\n") + "\n")
      system(@reload_cmd)
    end

    def add_entry(type, fqdn, ip)
      case type
      when 'A', 'AAAA'
        e = AddressEntry.new
        e.ip = ip
        e.fqdn = [fqdn]
      when 'PTR'
        e = PTREntry.new
        e.ip = IPAddr.new(ip).reverse
        e.fqdn = fqdn
      end

      configuration << e
      @dirty = true
    end

    def remove_entry(type, fqdn = nil, ip = nil)
      return true unless case type
      when 'A', 'AAAA'
        e = configuration.find { |entry| entry.is_a?(AddressEntry) && entry.fqdn.include?(fqdn) }
      when 'PTR'
        e = configuration.find { |entry| entry.is_a?(PTREntry) && entry.fqdn == fqdn }
      end

      configuration.delete e
      @dirty = true
    end

    def add_cname(name, canonical)
      # dnsmasq will silently ignore broken CNAME records, even though they stay in config
      # So avoid flooding the configuration if broken CNAME entries are added
      return true if configuration.find { |entry| entry.is_a?(CNAMEEntry) && entry.name == name }

      c = CNAMEEntry.new
      c.name = name
      c.target = canonical
      configuration << c
      @dirty = true
    end

    def remove_cname(name)
      c = configuration.find { |entry| entry.is_a?(CNAMEEntry) && entry.name == name }
      return true unless c

      configuration.delete c
      @dirty = true
    end

    private

    def load!
      @configuration = []
      File.open(@config_file).each_line do |line|
        line = line.strip
        next if line.empty? || line.start_with?('#') || !line.include?('=')

        option, value = line.split('=')

        case option
        when 'address'
          data = value.split('/')
          data.shift

          entry = AddressEntry.new
          entry.ip = data.pop
          entry.fqdn = data
        when 'cname'
          data = value.split(',')

          entry = CNAMEEntry.new
          entry.name = data.shift
          entry.target = data.shift
          entry.ttl = data.shift
        when 'ptr-record'
          data = value.split(',')

          entry = PTREntry.new
          entry.ip = data[0]
          entry.fqdn = data[1]
#       TODO: Handle these properly
#       when 'host-record'
#         data = value.split(',')

#         entry = HostEntry.new
#         until data.empty?
#           v = data.pop
#           if !entry.ttl && /\A\d+\z/ === v
#             entry.ttl = v
#           end

#           begin
#             ip = IPAddr.new(v)
#             entry.ip << v
#           rescue IPAddr::InvalidAddressError
#             entry.fqdn << v
#           end
#         end
        end

        @configuration << entry if entry
      end
    end

    def configuration
      load! unless @configuration
      @configuration
    end

    class AddressEntry
      attr_accessor :fqdn, :ip
      def initialize
        @fqdn = []
      end

      def to_s
        "address=/#{fqdn.join '/'}/#{ip}"
      end
    end

    class CNAMEEntry
      attr_accessor :name, :target, :ttl

      def to_s
        "cname=#{name},#{target}#{ttl && ',' + ttl}"
      end
    end

    class PTREntry
      attr_accessor :fqdn, :ip

      def to_s
        "ptr-record=#{ip},#{fqdn}"
      end
    end

    class HostEntry
      attr_accessor :ttl, :ip, :fqdn
      def initialize
        @fqdn = []
        @ip = []
      end

      def to_s
        "host-record=#{fqdn.join ','},#{ip.join ','}#{ttl && ',' + ttl}"
      end
    end
  end
end
