require 'test_helper'
require 'smart_proxy_dns_dnsmasq/dns_dnsmasq_main'
require 'smart_proxy_dns_dnsmasq/backend/default'

class DnsDnsmasqRecordDefaultTest < Test::Unit::TestCase
  def setup
    @provider = Proxy::Dns::Dnsmasq::Default.new('/etc/dnsmasq.d/foreman.conf', 'systemctl reload dnsmasq', 999)

    @provider.expects(:update!).returns(true)
    @configuration = mock()
    @provider.stubs(:configuration).returns(@configuration)
  end

  # Test A record creation
  def test_create_a
    fqdn = 'test.example.com'
    ip = '10.1.1.1'

    @configuration.expects(:<<).with { |val|
      val.is_a?(Proxy::Dns::Dnsmasq::Default::AddressEntry) &&
      val.fqdn == [fqdn] &&
      val.ip == ip
    }.returns(true)
    assert @provider.do_create(fqdn, ip, 'A')
  end

  # Test AAAA record creation
  def test_create_aaaa
    fqdn = 'test.example.com'
    ip = '2001:db8::1'

    @configuration.expects(:<<).with { |val|
      val.is_a?(Proxy::Dns::Dnsmasq::Default::AddressEntry) &&
      val.fqdn == [fqdn] &&
      val.ip == ip
    }.returns(true)
    assert @provider.do_create(fqdn, ip, 'AAAA')
  end

  # Test PTR record creation with an IPv4 address
  def test_create_ptr_v4
    fqdn = 'test.example.com'
    ip = '3.2.1.10.in-addr.arpa'

    @configuration.expects(:<<).with { |val|
      val.is_a?(Proxy::Dns::Dnsmasq::Default::PTREntry) &&
      val.fqdn == fqdn &&
      val.ip == ip
    }.returns(true)
    assert @provider.do_create(ip, fqdn, 'PTR')
  end

  # Test PTR record creation with an IPv6 address
  def test_create_ptr_v6
    fqdn = 'test.example.com'
    ip = '1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa' 

    @configuration.expects(:<<).with { |val|
      val.is_a?(Proxy::Dns::Dnsmasq::Default::PTREntry) &&
      val.fqdn == fqdn &&
      val.ip == ip
    }.returns(true)
    assert @provider.do_create(ip, fqdn, 'PTR')
  end

  # Test CNAME record creation
  def test_create_cname
    name = 'test.example.com'
    target = 'target.example.com'

    @configuration.expects(:find).returns(nil)
    @configuration.expects(:<<).with { |val|
      val.is_a?(Proxy::Dns::Dnsmasq::Default::CNAMEEntry) &&
      val.name == name &&
      val.target == target
    }.returns(true)
    assert @provider.do_create(name, target, 'CNAME')
  end

  # Test A record removal
  def test_remove_a
    @configuration.expects(:find).returns(Proxy::Dns::Dnsmasq::Default::AddressEntry.new)
    @configuration.expects(:delete).with { |v| v.is_a? Proxy::Dns::Dnsmasq::Default::AddressEntry }.returns(true)
    assert @provider.do_remove('test.example.com', 'A')
  end

  # Test AAAA record removal
  def test_remove_aaaa
    @configuration.expects(:find).returns(Proxy::Dns::Dnsmasq::Default::AddressEntry.new)
    @configuration.expects(:delete).with { |v| v.is_a? Proxy::Dns::Dnsmasq::Default::AddressEntry }.returns(true)
    assert @provider.do_remove('test.example.com', 'AAAA')
  end

  # Test PTR record removal with an IPv4 address
  def test_remove_ptr_v4
    @configuration.expects(:find).returns(Proxy::Dns::Dnsmasq::Default::PTREntry.new)
    @configuration.expects(:delete).with { |v| v.is_a? Proxy::Dns::Dnsmasq::Default::PTREntry }.returns(true)
    assert @provider.do_remove('3.2.1.10.in-addr.arpa', 'PTR')
  end

  # Test PTR record removal with an IPv6 address
  def test_remove_ptr_v6
    @configuration.expects(:find).returns(Proxy::Dns::Dnsmasq::Default::PTREntry.new)
    @configuration.expects(:delete).with { |v| v.is_a? Proxy::Dns::Dnsmasq::Default::PTREntry }.returns(true)
    assert @provider.do_remove('1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa', 'PTR')
  end

  # Test CNAME record removal
  def test_remove_cname
    @configuration.expects(:find).returns(Proxy::Dns::Dnsmasq::Default::CNAMEEntry.new)
    @configuration.expects(:delete).with { |v| v.is_a? Proxy::Dns::Dnsmasq::Default::CNAMEEntry }.returns(true)
    assert @provider.do_remove('test.example.com', 'CNAME')
  end
end
