require 'test_helper'
require 'smart_proxy_dns_dnsmasq/dns_dnsmasq_main'
require 'smart_proxy_dns_dnsmasq/backend/openwrt'

class DnsDnsmasqRecordOpenwrtTest < Test::Unit::TestCase
  def setup
    @provider = Proxy::Dns::Dnsmasq::Openwrt.new('/etc/config/dhcp', '/etc/init.d/dnsmasq reload', 999)

    @provider.expects(:update!).returns(true)
    @configuration = mock()
    @provider.stubs(:configuration).returns(@configuration)
  end

  # Test A record creation
  def test_create_a
    @provider.expects(:find_type).with(:domain, :name, 'test.example.com').returns(false)
    @configuration.expects(:<<).with { |val|
      val.is_a?(Proxy::Dns::Dnsmasq::Openwrt::DSL::Config) &&
      val.type == :domain &&
      val.options[:name] == 'test.example.com' &&
      val.options[:ip] == '10.1.1.1'
    }.returns(true)
    assert @provider.do_create('test.example.com', '10.1.1.1', 'A')
  end

  # Test PTR record creation with an IPv4 address
  def test_create_ptr_v4
    @provider.expects(:find_type).with(:domain, :name, 'test.example.com').returns(false)
    @configuration.expects(:<<).with { |val|
      val.is_a?(Proxy::Dns::Dnsmasq::Openwrt::DSL::Config) &&
      val.type == :domain &&
      val.options[:name] == 'test.example.com' &&
      val.options[:ip] == '10.1.2.3'
    }.returns(true)
    assert @provider.do_create('3.2.1.10.in-addr.arpa', 'test.example.com', 'PTR')
  end

  # Test CNAME record creation
  def test_create_cname
    @provider.expects(:find_type).with(:cname, :name, 'test.example.com').returns(false)
    @configuration.expects(:<<).with { |val|
      val.is_a?(Proxy::Dns::Dnsmasq::Openwrt::DSL::Config) &&
      val.type == :cname &&
      val.options[:cname] == 'test.example.com' &&
      val.options[:target] == 'target.example.com'
    }.returns(true)
    assert @provider.do_create('test.example.com', 'target.example.com', 'CNAME')
  end

  # Test A record removal
  def test_remove_a
    @provider.expects(:find_type).with(:domain, :name, 'test.example.com').returns(Proxy::Dns::Dnsmasq::Openwrt::DSL::Config.new(:domain))
    @configuration.expects(:delete).with { |val|
      val.is_a?(Proxy::Dns::Dnsmasq::Openwrt::DSL::Config) &&
      val.type == :domain
    }.returns(true)
    assert @provider.do_remove('test.example.com', 'A')
  end

  # Test PTR record removal with an IPv4 address
  def test_remove_ptr_v4
    @provider.expects(:find_type).with(:domain, :ip, '10.1.2.3').returns(Proxy::Dns::Dnsmasq::Openwrt::DSL::Config.new(:domain))
    @configuration.expects(:delete).with { |val|
      val.is_a?(Proxy::Dns::Dnsmasq::Openwrt::DSL::Config) &&
      val.type == :domain
    }.returns(true)
    assert @provider.do_remove('3.2.1.10.in-addr.arpa', 'PTR')
  end

  # Test CNAME record removal
  def test_remove_cname
    @provider.expects(:find_type).with(:cname, :name, 'test.example.com').returns(Proxy::Dns::Dnsmasq::Openwrt::DSL::Config.new(:cname))
    @configuration.expects(:delete).with { |val|
      val.is_a?(Proxy::Dns::Dnsmasq::Openwrt::DSL::Config) &&
      val.type == :cname
    }.returns(true)
    assert @provider.do_remove('test.example.com', 'CNAME')
  end
end
