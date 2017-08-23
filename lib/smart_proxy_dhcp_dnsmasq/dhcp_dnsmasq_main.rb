require 'fileutils'
require 'tempfile'
require 'dhcp_common/server'

module Proxy::DHCP::Dnsmasq
  class Record < ::Proxy::DHCP::Server
    attr_reader :config_dir, :reload_cmd, :subnet_service

    def initialize(target_dir, reload_cmd, subnet_service)
      @config_dir = target_dir
      @reload_cmd = reload_cmd
      @subnet_service = subnet_service
      @optsfile_content = []

      Dir.mkdir @config_dir unless Dir.exist? @config_dir

      subnet_service.load!

      super('localhost', nil, subnet_service)
    end

    def add_record(options = {})
      logger.debug "Adding record; #{options}"
      record = super(options)
      options = record.options

      tags = []
      tags << ensure_bootfile(options[:filename]) if options[:filename]
      tags << ensure_tftpserver(options[:nextServer]) if options[:nextServer]
      tagstring = ",set:#{tags.join(',set:')}" unless tags.empty?

      hostspath = File.join(@config_dir, 'dhcphosts')
      Dir.mkdir hostspath unless Dir.exist? hostspath
      File.write(File.join(hostspath, "#{sanitize_string record.mac}.conf"),
                 "#{record.mac}#{tagstring},#{record.ip},#{record.name}\n")
      subnet_service.add_host(record.subnet_address, record)

      try_reload_cmd
      record
    end

    def del_record(record)
      logger.debug "Deleting record; #{record}"
      # TODO: Removal of leases, to prevent DHCP record collisions?
      return record if record.is_a? ::Proxy::DHCP::Lease

      path = File.join(@config_dir, 'dhcphosts', "#{sanitize_string record.mac}.conf")
      File.unlink(path) if File.exist? path

      subnet_service.delete_host(record)

      try_reload_cmd
      record
    end

    private

    def try_reload_cmd
      logger.debug 'Reloading DHCP configuration...'
      raise Proxy::DHCP::Error, 'Failed to reload configuration' \
        unless system(@reload_cmd)
    end

    def optsfile_content
      path = File.join(@config_dir, 'dhcpopts.conf').freeze

      @optsfile_content = open(path).readlines \
        if File.exist?(path) && @optsfile_content.empty?
      @optsfile_content
    end

    def append_optsfile(line)
      path = File.join(@config_dir, 'dhcpopts.conf').freeze
      logger.debug "Appending #{line} to dhcpopts.conf"

      optsfile_content << line
      File.write(path, optsfile_content.join("\n") + "\n")
    end

    def sanitize_string(string)
      string.gsub(/[^0-9A-Za-z]/, '_')
    end

    def ensure_bootfile(filename)
      tagname = "bf_#{sanitize_string(filename)}"

      append_optsfile "tag:#{tagname},option:bootfile-name,#{filename}" \
        unless optsfile_content.find { |l| l.start_with? "tag:#{tagname}" }

      tagname
    end

    def ensure_tftpserver(address)
      tagname = "ns_#{sanitize_string(address)}"

      append_optsfile "tag:#{tagname},option:tftp-server,#{address}" \
        unless optsfile_content.find { |l| l.start_with? "tag:#{tagname}" }

      tagname
    end
  end
end
