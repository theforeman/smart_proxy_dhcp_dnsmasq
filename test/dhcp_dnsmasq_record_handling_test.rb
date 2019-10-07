# frozen_string_literal: true

require 'test_helper'
require 'smart_proxy_dhcp_dnsmasq/dhcp_dnsmasq_main'

class DHCPDnsmasqRecordHandlingTest < Test::Unit::TestCase
  def setup
    @free_ips = mock
    @subnet_service = mock
    @subnet_service.expects(:load!).returns(true)
    @subnet_service.expects(:cleanup_time?).returns(false)
    @subnet_service.stubs(:last_cleanup=)
    Dir.stubs(:exist?).returns(true)
    Proxy::LogBuffer::Decorator.any_instance.stubs(:add)

    @server = ::Proxy::DHCP::Dnsmasq::Provider.new('/etc/dnsmasq.d/', '/bin/true', @subnet_service, @free_ips)
    @server.instance_eval('@optsfile_content = []')
  end

  def test_add_record
    Proxy::DHCP::Dnsmasq::Provider.any_instance.expects(:cleanup_optsfile).never

    subnet = ::Proxy::DHCP::Subnet.new('10.0.0.0', '255.0.0.0')
    @subnet_service.stubs(:find_subnet).with('10.0.0.0').returns(subnet)
    @subnet_service.stubs(:find_hosts_by_ip).returns(nil)
    @subnet_service.stubs(:find_host_by_mac).returns(nil)
    @subnet_service.stubs(:find_lease_by_ip).returns(nil)
    @subnet_service.stubs(:find_lease_by_mac).returns(nil)

    File.expects(:write).with(
      '/etc/dnsmasq.d/dhcphosts/00_01_02_03_04_05.conf',
      "00:01:02:03:04:05,set:bf_bootfile,set:ns_10_0_0_2,10.0.0.1,hostname\n"
    )
    @server.expects(:append_optsfile)
           .with('tag:bf_bootfile,option:bootfile-name,bootfile').returns(true)
    @server.expects(:append_optsfile)
           .with('tag:ns_10_0_0_2,option:tftp-server,10.0.0.2').returns(true)
    @subnet_service.expects(:add_host).returns(true)
    @server.expects(:try_reload_cmd).returns(nil)

    @server.add_record(
      'hostname' => 'hostname',
      'ip' => '10.0.0.1',
      'network' => '10.0.0.0',
      'mac' => '00:01:02:03:04:05',
      filename: 'bootfile',
      nextServer: '10.0.0.2'
    )
  end

  def test_del_record
    subnet = ::Proxy::DHCP::Subnet.new('10.0.0.0', '255.0.0.0')
    host = ::Proxy::DHCP::Reservation.new('10.0.0.0', '255.0.0.0', '00:01:02:03:04:05', subnet)
    @subnet_service.expects(:delete_host).with(host).returns(true)

    File.expects(:exist?).with('/etc/dnsmasq.d/dhcphosts/00_01_02_03_04_05.conf').returns(true)
    File.expects(:unlink).with('/etc/dnsmasq.d/dhcphosts/00_01_02_03_04_05.conf').returns(true)
    @server.expects(:try_reload_cmd).returns(nil)

    @server.del_record(host)
  end

  def test_optsfile_reading
    @server.stubs(:optsfile_path).returns 'test/fixtures/dhcpopts.conf'

    assert_equal %w[
      tag:bf_pxelinux_0,option:bootfile-name,pxelinux.0
      tag:bf_pxelinux_1,option:bootfile-name,pxelinux.1
      tag:bf_pxelinux_2,option:bootfile-name,pxelinux.2
      tag:bf_pxelinux_3,option:bootfile-name,pxelinux.3
      tag:bf_pxelinux_4,option:bootfile-name,pxelinux.4
      tag:ns_tftp_server,option:tftp-server,tftp.server
      tag:ns_tftp_server_local,option:tftp-server,tftp.server.local
    ], @server.send(:optsfile_content)
  end

  def test_optsfile_append
    @server.stubs(:optsfile_path).returns '/dev/null'
    @server.instance_variable_set :@optsfile_content, %w[tag:bf_pxelinux_0,option:bootfile-name,pxelinux.0]

    File.expects(:write).with('/dev/null', "tag:bf_pxelinux_0,option:bootfile-name,pxelinux.0\ntag:ns_tftp_server_local,option:tftp-server.local\n")

    @server.send :append_optsfile, 'tag:ns_tftp_server_local,option:tftp-server.local'
  end

  def test_optsfile_cleanup
    @server.stubs(:optsfile_path).returns '/dev/null'
    @server.instance_variable_set :@optsfile_content, %w[tag:bf_pxelinux_0,option:bootfile-name,pxelinux.0]

    Dir.expects(:glob).returns([])
    File.expects(:write).with('/dev/null', "\n")

    @server.send :cleanup_optsfile
  end

  def test_optsfile_cleanup_real
    @server.stubs(:optsfile_path).returns 'test/fixtures/dhcpopts.conf'
    @server.instance_variable_set :@config_dir, 'test/fixtures'

    File.expects(:write).with('test/fixtures/dhcpopts.conf', "tag:bf_pxelinux_0,option:bootfile-name,pxelinux.0\ntag:ns_tftp_server_local,option:tftp-server,tftp.server.local\n")

    @server.send :cleanup_optsfile
  end
end
