require 'test_helper'
require 'smart_proxy_dhcp_dnsmasq/dhcp_dnsmasq_subnet_service'

class DHCPDnsmasqSubnetServiceTest < Test::Unit::TestCase
  def setup
    @subnet_service = mock()
  end

  def test_initialize
    subnet = ::Proxy::DHCP::Subnet.new('10.0.0.0','255.255.255.0') 
    host = ::Proxy::DHCP::Reservation.new('test','10.0.0.10','ba:be:fa:ce:ca:fe',subnet)
    lease = ::Proxy::DHCP::Lease.new('test','10.0.0.10','ba:be:fa:ce:ca:fe',subnet,Time.now,Time.now + 1000,'active')

    @subnet_service.expects(:add_subnet).with(subnet)
    @subnet_service.expects(:add_host)
    @subnet_service.expects(:add_lease)

    initializer = Proxy::DHCP::Dnsmasq::SubnetService.new('config/file', 'lease/file')
    initializer.expects(:parse_config_for_subnet).returns(subnet)
    initializer.expects(:parse_config_for_dhcp_reservations).returns([ host ])
    initializer.expects(:load_leases).returns([ lease ])
    initializer.initialized_subnet_service(@subnet_service)
  end
end
