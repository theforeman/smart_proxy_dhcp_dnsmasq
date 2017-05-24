require 'fileutils'
require 'tempfile'
require 'dhcp_common/server'

module Proxy::DHCP::Dnsmasq
  class Record < ::Proxy::DHCP::Server
    attr_reader :write_config_dir, :config_dir, :reload_cmd, :subnet_service

    def initialize(write_config_dir, config_dir, reload_cmd, subnet_service)
      @write_config_dir = write_config_dir
      @config_dir = config_dir
      @reload_cmd = reload_cmd
      @subnet_service = subnet_service

      subnet_service.load!

      super('localhost', nil, subnet_service)
    end

    def add_record(options={})
      record = super(options)
      options = record.options

      open("#{@write_config_dir}/hostsfile/#{record.mac}.conf", 'w') do |file|
        file.puts "set:#{record.mac},#{record.mac},#{record.ip},#{record.name}"
      end

      if options[:filename] && options[:nextServer]
        open("#{@write_config_dir}/optsfile/#{record.mac}.conf", 'w') do |file|
          file.puts "tag:#{record.mac},option:tftp-server,#{options[:nextServer]}"
          file.puts "tag:#{record.mac},option:bootfile-name,#{options[:filename]}"
        end
      end

      subnet_service.add_host(record)

      raise Proxy::DHCP::Error, 'Failed to reload configuration' unless system(@reload_cmd)

      record
    end

    def del_record(record)
      # TODO: Removal of leases, to prevent DHCP record collisions
      return record if record.is_a? ::Proxy::DHCP::Lease

      File.unlink("#{@write_config_dir}/optsfile/#{record.mac}.conf") if\
        File.exist? "#{@write_config_dir}/optsfile/#{record.mac}.conf"
      File.unlink("#{@write_config_dir}/hostsfile/#{record.mac}.conf") if\
        File.exist? "#{@write_config_dir}/hostsfile/#{record.mac}.conf"

      subnet_service.delete_host(record)

      raise Proxy::DHCP::Error, 'Failed to reload configuration' unless system(@reload_cmd)

      record
    end
  end
end
