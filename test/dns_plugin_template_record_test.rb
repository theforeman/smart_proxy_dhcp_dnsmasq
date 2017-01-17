require 'test_helper'
require 'smart_proxy_dns_plugin_template/dns_plugin_template_main'


class DnsPluginTemplateRecordTest < Test::Unit::TestCase
  def setup
    @provider = Proxy::Dns::PluginTemplate::Record.new('required_value', 'a_value', '/required/path', '/some/path', 999)
  end

  # These tests are very verbose and possibly a lot of duplication, but it is a
  # somewhat complete overview of the possible inputs.

  # Test A record creation
  def test_create_a
    # Use mocha to expect any calls to backend services to prevent creating real records
    #   MyService.expects(:create_address_v4).with(:value => '10.1.1.1', :name => 'test.example.com').returns(true)
    assert @provider.do_create('test.example.com', '10.1.1.1', 'A')
  end

  # Test AAAA record creation
  def test_create_aaaa
    # Use mocha to expect any calls to backend services to prevent creating real records
    #   MyService.expects(:create_address_v6).with(:value => '2001:db8::1', :name => 'test.example.com').returns(true)
    assert @provider.do_create('test.example.com', '2001:db8::1', 'AAAA')
  end

  # Test PTR record creation with an IPv4 address
  def test_create_ptr_v4
    # Use mocha to expect any calls to backend services to prevent creating real records
    #   MyService.expects(:create_reverse).with(:value => 'test.example.com', :name => '3.2.1.10.in-addr.arpa').returns(true)
    assert @provider.do_create('3.2.1.10.in-addr.arpa', 'test.example.com', 'PTR')
  end

  # Test PTR record creation with an IPv6 address
  def test_create_ptr_v6
    # Use mocha to expect any calls to backend services to prevent creating real records
    #   MyService.expects(:create_reverse).with(:value => 'test.example.com', :name => '1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa').returns(true)
    assert @provider.do_create('1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa', 'test.example.com', 'PTR')
  end

  # Test CNAME record creation
  def test_create_cname
    # Use mocha to expect any calls to backend services to prevent creating real records
    #   MyService.expects(:create_cname).with(:value => 'target.example.com', :name => 'test.example.com').returns(true)
    assert @provider.do_create('test.example.com', 'target.example.com', 'CNAME')
  end

  # Test A record removal
  def test_remove_a
    # Use mocha to expect any calls to backend services to prevent deleting real records
    #   MyService.expects(:delete_address_v4).with(:name => 'test.example.com').returns(true)
    assert @provider.do_remove('test.example.com', 'A')
  end

  # Test AAAA record removal
  def test_remove_aaaa
    # Use mocha to expect any calls to backend services to prevent deleting real records
    #   MyService.expects(:delete_address_v6).with(:name => 'test.example.com').returns(true)
    assert @provider.do_remove('test.example.com', 'AAAA')
  end

  # Test PTR record removal with an IPv4 address
  def test_remove_ptr_v4
    # Use mocha to expect any calls to backend services to prevent deleting real records
    #   MyService.expects(:delete_reverse).with(:name => '3.2.1.10.in-addr.arpa').returns(true)
    assert @provider.do_remove('3.2.1.10.in-addr.arpa', 'PTR')
  end

  # Test PTR record removal with an IPv6 address
  def test_remove_ptr_v6
    # Use mocha to expect any calls to backend services to prevent deleting real records
    #   MyService.expects(:delete_reverse).with(:name => '1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa').returns(true)
    assert @provider.do_remove('1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa', 'PTR')
  end

  # Test CNAME record removal
  def test_remove_cname
    # Use mocha to expect any calls to backend services to prevent deleting real records
    #   MyService.expects(:delete_cname).with(:name => 'test.example.com').returns(true)
    assert @provider.do_remove('test.example.com', 'CNAME')
  end
end
