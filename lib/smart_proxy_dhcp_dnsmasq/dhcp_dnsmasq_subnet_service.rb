require 'ipaddr'
#require 'rb-inotify'
require 'dhcp_common/dhcp_common'
require 'dhcp_common/subnet_service'
require 'smart_proxy_dhcp_dnsmasq/dhcp_dnsmasq_utils'

module Proxy::DHCP::Dnsmasq
  class SubnetService < ::Proxy::DHCP::SubnetService
    include Proxy::Log

    attr_reader :config_dir, :lease_file

    def initialize(config, target_dir, lease_file, leases_by_ip, leases_by_mac, reservations_by_ip, reservations_by_mac, reservations_by_name)
      @config_paths = [config].flatten
      @target_dir = target_dir
      @lease_file = lease_file

      super(leases_by_ip, leases_by_mac, reservations_by_ip, reservations_by_mac, reservations_by_name)
    end

    def load!
      parse_config_for_subnets.each { |subnet| add_subnet(subnet) }
      load_subnet_data
      #add_watch # TODO

      true
    end

    def add_watch
      # TODO: Add proper inotify listener for configs
      @inotify = INotify::Notifier.new
      @inotify.watch(File.dirname(lease_file), :modify, :moved_to) do |ev|
        next unless ev.absolute_name == lease_file

        leases = load_leases

        # FIXME: Proper method for this
        m.synchronize do
          leases_by_ip.clear
          leases_by_mac.clear
        end
        leases.each { |l| add_lease(l.subnet_address, l) }
      end
    end

    def parse_config_for_subnets
      configuration = { options: {} }
      files = []
      subnets = []
      @config_paths.each do |path|
        files << path if File.exist? path
        files += Dir["#{path}/*"] if Dir.exist? path
      end

      interfaces = Socket.getifaddrs
      available_interfaces = nil
      logger.debug "Starting parse of DHCP subnets from #{files}"
      files.each do |file|
        logger.debug "  Parsing #{file}..."
        open(file, 'r').each_line do |line|
          line.strip!
          next if line.empty? || line.start_with?('#') || !line.include?('=')

          option, value = line.split('=')
          case option
          when 'interface'
            iface = interfaces.find { |i| i.name == value }
            logger.debug "Adding DNS interface: #{value} => #{iface.inspect}"
            (available_interfaces ||= []) << iface if iface
          when 'no-dhcp-interface'
            available_interfaces ||= interfaces
            available_interfaces.delete_if { |i| i.name == value }
            logger.debug "Removed DNS interface: #{value}"
          when 'dhcp-leasefile'
            next if @lease_file

            @lease_file = value
          when 'dhcp-range'
            data = value.split(',')
            tags = Proxy::DHCP::Dnsmasq.parse_tags(data)

            subnet_id = tags.set ||
                        (data.first if (available_interfaces || interfaces).find { |i| i.name == data.first }) ||
                        'default'

            logger.warning "Found subnet #{subnet_id} multiple times." if configuration.key? subnet_id

            subnet_iface = data.shift if interfaces.include?(data.first) || /^\w+$/ =~ data.first
            subnet_iface ||= (available_interfaces || interfaces)[configuration.count].name

            range_from = data.shift
            range_to = data.shift
            mask = data.shift if data.first =~ /^(\d{1,3}\.){3}\d{1,3}$/ || data.first =~ /^(\a+:+)+(\a+)$/
            mask ||= '255.255.255.0' # TODO: Grab from interface IP
            ttl = data.shift if data.first =~ /^\d+[mh]|infinite|deprecated$/

            ttl = case ttl[-1]
                  when 'h'
                    ttl[0..-2].to_i * 60 * 60
                  when 'm'
                    ttl[0..-2].to_i * 60
                  else
                    ttl.to_i
                  end if ttl
            ttl ||= 1 * 60 * 60 # Default lease time is one hour

            data = (configuration[subnet_id] ||= {})
            data.merge! \
              interface: subnet_iface,
              address: IPAddr.new("#{range_from}/#{mask}").to_s,
              mask: mask,
              range: [range_from, range_to],
              ttl: ttl

            (data[:options] ||= {}).merge! \
              range: data[:range]

            # TODO: Handle this in a better manner
            @ttl = data[:ttl]
          when 'dhcp-option'
            data = value.split(',')
            tags = Proxy::DHCP::Dnsmasq.parse_tags(data)

            subnet_id = (tags.tags.empty? ? nil : tags.tags) ||
                        (data.first if (available_interfaces || interfaces).find { |i| i.name == data.first }) ||
                        interfaces[configuration.count].name || 'default'

            data.shift until data.empty? || /\A\d+\z/ =~ data.first
            next if data.empty?

            code = data.shift.to_i

            option = ::Proxy::DHCP::Standard.select { |_k, v| v[:code] == code }.first.first

            data = data.first unless ::Proxy::DHCP::Standard[option][:is_list]

            [subnet_id].flatten.each do |id|
              ((configuration[id] ||= {})[:options] ||= {})[option] = data
            end
          end
        end
      end

      configuration.each do |id, data|
        logger.debug "Adding subnet #{id} with configuration; #{data}"
        subnets << ::Proxy::DHCP::Subnet.new(data[:address], data[:mask], data[:options])
      end

      subnets
    end

    # Expects subnet_service to have subnet data
    def parse_config_for_dhcp_reservations
      to_ret = {}
      files = []
      @config_paths.each do |path|
        files << path if File.exist? path
        files += Dir[File.join(path), '*'] if Dir.exist? path
      end

      logger.debug "Starting parse of DHCP reservations from #{files}"
      files.each do |file|
        logger.debug "  Parsing #{file}..."
        File.open(file, 'r').each_line do |line|
          line.strip!
          next if line.empty? || line.start_with?('#') || !line.include?('=')

          option, value = line.split('=')
          case option
          when 'dhcp-host'
            data = value.split(',')
            Proxy::DHCP::Dnsmasq.parse_tags(data)

            mac, ip, hostname = data[0, 3]

            # TODO: Possible ttl on end

            subnet = find_subnet(ip)
            to_ret[mac] = ::Proxy::DHCP::Reservation.new(
              hostname,
              ip,
              mac,
              subnet,
              # :source_file => file # TODO: Needs to overload the comparison
            )
          when 'dhcp-boot'
            data = value.split(',')
            tags = Proxy::DHCP::Dnsmasq.parse_tags(data)
            next if tags.tags.empty?
            mac = tags.tags.find { |t| /^(\w{2}:){5}\w{2}$/ =~ t }
            next if mac.nil?

            next unless to_ret.key? mac

            file, server = data

            to_ret[mac].options[:nextServer] = file
            to_ret[mac].options[:filename] = server
          end
        end
      end
      dhcpoptions = {}

      dhcpopts_path = File.join(@target_dir, 'dhcpopts.conf')
      logger.debug "Parsing DHCP options from #{dhcpopts_path}"
      if File.exist? dhcpopts_path
        open(dhcpopts_path, 'r').each_line do |line|
          data = line.strip.split(',')
          next if data.empty? || !data.first.start_with?('tag:')

          tags = Proxy::DHCP::Dnsmasq.parse_tags(data)
          dhcpoptions[tags.tag] = data.last
        end
      end

      logger.debug "Parsing provisioned DHCP reservations from #{@target_dir}"
      Dir[File.join(@target_dir, 'dhcphosts', '*')].each do |file|
        logger.debug "  Parsing #{file}..."
        open(file, 'r').each_line do |line|
          data = line.strip.split(',')
          next if data.empty? || data.first.start_with?('#')

          mac = data.first
          data.shift

          options = { :deletable => true }
          tags = Proxy::DHCP::Dnsmasq.parse_tags(data)
          tags.sets.each do |tag|
            value = dhcpoptions[tag]
            next if value.nil?

            options[:nextServer] = value if tag.start_with? 'ns'
            options[:filename] = value if tag.start_with? 'bf'
          end

          ip, name = data
          subnet = find_subnet(ip)

          to_ret[mac] = ::Proxy::DHCP::Reservation.new(
            name, ip, mac, subnet, options
          )
        end
      end

      to_ret.values
    rescue StandardError => e
      logger.error msg = "Unable to parse reservations: #{e}"
      raise Proxy::DHCP::Error, e, msg
    end

    def load_subnet_data
      reservations = parse_config_for_dhcp_reservations
      reservations.each do |record|
        if dupe = find_host_by_mac(record.subnet_address, record.mac)
          logger.debug "Found duplicate #{dupe} when adding record #{record}, skipping"
          next
        end

        # logger.debug "Adding host #{record}"
        add_host(record.subnet_address, record)
      end

      leases = load_leases
      leases.each do |lease|
        if dupe = find_lease_by_mac(lease.subnet_address, lease.mac)
          logger.debug "Found duplicate #{dupe} by MAC when adding lease #{lease}, skipping"
          next
        end
        if dupe = find_lease_by_ip(lease.subnet_address, lease.ip)
          logger.debug "Found duplicate #{dupe} by IP when adding lease #{lease}, skipping"
          next
        end

        # logger.debug "Adding lease #{lease}"
        add_lease(lease.subnet_address, lease)
      end
    end

    # Expects subnet_service to have subnet data
    def load_leases
      open(@lease_file, 'r').readlines.map do |line|
        timestamp, mac, ip, _hostname, _client_id = line.split
        timestamp = timestamp.to_i

        subnet = find_subnet(ip)
        ::Proxy::DHCP::Lease.new(
          nil, ip, mac, subnet,
          timestamp - (@ttl || 24 * 60 * 60),
          timestamp,
          'active'
        )
      end
    end
  end
end
