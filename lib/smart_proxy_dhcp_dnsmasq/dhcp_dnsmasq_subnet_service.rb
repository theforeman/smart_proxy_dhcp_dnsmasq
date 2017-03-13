require 'ipaddr'
require 'rb-inotify'
require 'dhcp_common/subnet_service'

module Proxy::DHCP::Dnsmasq
  class SubnetService < ::Proxy::DHCP::SubnetService
    include Proxy::Log

    attr_reader :config_file, :lease_file

    def initialize(config_files, lease_file, leases_by_ip, leases_by_mac, reservations_by_ip, reservations_by_mac, reservations_by_name)
      @config_files = config_files
      @lease_file = lease_file

      super(leases_by_ip, leases_by_mac, reservations_by_ip, reservations_by_mac, reservations_by_name)
    end

    def load!
      add_subnet(parse_config_for_subnet)
      load_subnet_data
      add_watch

      true
    end

    def add_watch
      # TODO: Add proper inotify listener for configs
      @inotify = INotify::Notifier.new
      @inotify.watch(File.dirname(lease_file), :modify, :moved_to) do |ev|
        next unless ev.absolute_name == lease_file

        leases = load_leases(subnet_service)
        
        # FIXME: Proper method for this
        m.synchronize do
          leases_by_ip.clear
          leases_by_mac.clear
        end
        leases.each { |l| add_lease(l.subnet_address, l) }
      end
    end

    def parse_config_for_subnet
      configuration = { }
      @config_files.each do |file|
        open(file, 'r').each_line do |line|
          line.strip!
          next if line.empty? || line.start_with?('#') || !line.include?('=')

          option, value = line.split('=')
          case option
          when 'dhcp-leasefile'
            next if @lease_file

            @lease_file = value
          when 'dhcp-range'
            data = value.split(',')
            
            ttl = data.pop
            mask = data.pop
            range_to = data.pop
            range_from = data.pop

            case ttl[-1]
            when 'h'
              ttl = ttl[0..-2].to_i * 60 * 60
            when 'm'
              ttl = ttl[0..-2].to_i * 60
            else
              ttl = ttl.to_i
            end

            configuration.merge! address: IPAddr.new("#{range_from}/#{mask}").to_s,
                                 mask: mask,
                                 range: [ range_from, range_to ],
                                 ttl: ttl
          when 'dhcp-option'
            data = value.split(',')

            configuration[:options] = {} unless configuration.key? :options

            until data.empty? || /\A\d+\z/ === data.first
              data.shift
            end
            next if data.empty?

            code = data.shift.to_i
            option = ::Proxy::DHCP::Standard.select { |k, v| v[:code] == code }.first.first

            data = data.first unless ::Proxy::DHCP::Standard[option][:is_list]
            configuration[:options][option] = data
          end
        end
      end

      ::Proxy::DHCP::Subnet.new(configuration[:address], configuration[:mask], configuration[:options])
    end

    # Expects subnet_service to have subnet data
    def parse_config_for_dhcp_reservations(files = @config_files)
      to_ret = []
      files.each do |file|
        open(file, 'r').each_line do |line|
          line.strip!
          next if line.empty? || line.start_with?('#') || !line.include?('=')

          option, value = line.split('=')
          case option
          when 'dhcp-host'
            mac, ip, hostname = value.split(',')

            subnet = find_subnet(ip)
            to_ret << ::Proxy::DHCP::Reservation.new(
              hostname,
              ip,
              mac,
              subnet,
              :hostname => hostname,
              :source_file => file
            )
          end
        end
      end
      to_ret
    rescue Exception => e
      logger.error msg = "Unable to parse reservations: #{e}"
      raise Proxy::DHCP::Error, msg
    end

    def load_subnet_data
      reservations = parse_config_for_dhcp_reservations
      reservations.each { |record| add_host(record.subnet_address, record) }
      leases = load_leases
      leases.each { |lease| add_lease(lease.subnet_address, lease) }
    end

    # Expects subnet_service to have subnet data
    def load_leases
      leases = []
      open(@lease_file, 'r').each_line do |line|
        timestamp, mac, ip, hostname, client_id = line.split

        subnet = find_subnet(ip)
        leases << ::Proxy::DHCP::Lease.new(
          client_id,
          ip,
          mac,
          subnet,
          timestamp - @configuration[:ttl],
          timestamp,
          'active')
      end
      leases
    end
  end
end
