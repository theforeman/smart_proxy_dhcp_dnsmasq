require 'test_helper'
require 'smart_proxy_dhcp_dnsmasq/dhcp_dnsmasq_main'

class DHCPDnsmasqRecordHandlingTest < Test::Unit::TestCase
  def setup
    @subnet_service = mock
    @subnet_service.expects(:load!).returns(true)
    Dir.stubs(:exist?).returns(true)

    @server = ::Proxy::DHCP::Dnsmasq::Record.new('/etc/dnsmasq.d/', '/bin/true', @subnet_service)
    @server.instance_eval('@optsfile_content = []')
  end

  def test_add_record
    subnet = ::Proxy::DHCP::Subnet.new('10.0.0.0', '255.0.0.0')
    @subnet_service.expects(:find_subnet).with('10.0.0.0').returns(subnet)
    @subnet_service.expects(:find_hosts_by_ip).returns(nil)
    @subnet_service.expects(:find_host_by_mac).returns(nil)

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
    @subnet_service.expects(:delete_host).with('10.0.0.0', host).returns(true)

    File.expects(:exist?).with('/etc/dnsmasq.d/dhcphosts/00_01_02_03_04_05.conf').returns(true)
    File.expects(:unlink).with('/etc/dnsmasq.d/dhcphosts/00_01_02_03_04_05.conf').returns(true)
    @server.expects(:try_reload_cmd).returns(nil)

    @server.del_record(host)
  end
end
