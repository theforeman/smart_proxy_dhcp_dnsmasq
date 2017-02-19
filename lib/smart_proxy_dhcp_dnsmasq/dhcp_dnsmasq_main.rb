module Proxy::DHCP::Dnsmasq
  class Record < ::Proxy::DHCP::Server
    attr_reader :config_file, :reload_cmd

    def initialize(config_file, reload_cmd, subnet_service)
      @config_file = config_file
      @reload_cmd = reload_cmd

      super('localhost', nil, subnet_service)
    end

    def add_record(options={})
      record = super(options)

      open(@config_file, 'a') do |file|
        file.puts "dhcp-host=#{record.mac},#{record.ip},#{record.name}"
      end
      raise Proxy::DHCP::Error, 'Failed to reload configuration' unless system(@reload_cmd)

      record
    end

    def del_record(record)
      to_write = []
      open(@config_file, 'r').each_line do |line|
        to_write << line unless line.start_with? "dhcp-host=#{record.mac}"
      end
      File.write(@config_file, to_write.join("\n"))

      raise Proxy::DHCP::Error, 'Failed to reload configuration' unless system(@reload_cmd)

      record
    end
  end
end
