require 'test_helper'
require 'smart_proxy_dns_plugin_template/dns_plugin_template_main'


class DnsPluginTemplateRecordTest < Test::Unit::TestCase
  def setup
    @provider = Proxy::Dns::PluginTemplate::Record.new('required_value', 'a_value', '/required/path', '/some/path', 999)
  end

  # Test that a missing :example_setting throws an error
  # Test A record creation
  def test_create_a
    # Use mocha to expect any calls to backend services to prevent creating real records
    #   MyService.expects(:create).with(:ip => '10.1.1.1', :name => 'test.example.com').returns(true)
    @provider.expects(:a_record_conflicts).with('test.example.com', '10.1.1.1').returns(-1)
    assert @provider.create_a_record('test.example.com', '10.1.1.1')
  end

  # Test A record creation fails if the record exists
  def test_create_a_conflict
    # Use mocha to expect any calls to backend services to prevent creating real records
    #   MyService.expects(:create).with(:ip => '10.1.1.1', :name => 'test.example.com').returns(false)
    @provider.expects(:a_record_conflicts).with('test.example.com', '10.1.1.1').returns(1)
    assert_raise(Proxy::Dns::Collision) { @provider.create_a_record('test.example.com', '10.1.1.1') }
  end

  # Test AAAA record creation
  def test_create_aaaa
    # Use mocha to expect any calls to backend services to prevent creating real records
    #   MyService.expects(:create).with(:ip => '2001:db8::1', :name => 'test.example.com').returns(true)
    @provider.expects(:aaaa_record_conflicts).with('test.example.com', '2001:db8::1').returns(-1)
    assert @provider.create_aaaa_record('test.example.com', '2001:db8::1')
  end

  # Test AAAA record creation fails if the record exists
  def test_create_aaaa_conflict
    # Use mocha to expect any calls to backend services to prevent creating real records
    #   MyService.expects(:create).with(:ip => '2001:db8::1', :name => 'test.example.com').returns(false)
    @provider.expects(:aaaa_record_conflicts).with('test.example.com', '2001:db8::1').returns(1)
    assert_raise(Proxy::Dns::Collision) { @provider.create_aaaa_record('test.example.com', '2001:db8::1') }
  end

  # Test PTR record creation
  def test_create_ptr
    # Use mocha to expect any calls to backend services to prevent creating real records
    #   MyService.expects(:create_reverse).with(:ip => '10.1.1.1', :name => 'test.example.com').returns(true)
    @provider.expects(:ptr_record_conflicts).with('test.example.com', '10.1.1.1').returns(-1)
    assert @provider.create_ptr_record('test.example.com', '1.1.1.10.in-addr.arpa')
  end

  # Test PTR record creation fails if the record exists
  def test_create_ptr_conflict
    # Use mocha to expect any calls to backend services to prevent creating real records
    #   MyService.expects(:create_reverse).with(:ip => '10.1.1.1', :name => 'test.example.com').returns(false)
    @provider.expects(:ptr_record_conflicts).with('test.example.com', '10.1.1.1').returns(1)
    assert_raise(Proxy::Dns::Collision) { @provider.create_ptr_record('test.example.com', '1.1.1.10.in-addr.arpa') }
  end

  # Test A record removal
  def test_remove_a
    # Use mocha to expect any calls to backend services to prevent deleting real records
    #   MyService.expects(:delete).with(:name => 'test.example.com').returns(true)
    @provider.expects(:dns_find).with('test.example.com').returns(true)
    assert @provider.remove_a_record('test.example.com')
  end

  # Test A record removal fails if the record doesn't exist
  def test_remove_a_not_found
    # Use mocha to expect any calls to backend services to prevent deleting real records
    #   MyService.expects(:delete).with(:name => 'test.example.com').returns(false)
    @provider.expects(:dns_find).with('test.example.com').returns(false)
    assert_raise(Proxy::Dns::NotFound) { assert @provider.remove_a_record('test.example.com') }
  end

  # Test AAAA record removal
  def test_remove_aaaa
    # Use mocha to expect any calls to backend services to prevent deleting real records
    #   MyService.expects(:delete).with(:name => 'test.example.com').returns(true)
    @provider.expects(:dns_find).with('test.example.com').returns(true)
    assert @provider.remove_aaaa_record('test.example.com')
  end

  # Test AAAA record removal fails if the record doesn't exist
  def test_remove_aaaa_not_found
    # Use mocha to expect any calls to backend services to prevent deleting real records
    #   MyService.expects(:delete).with(:name => 'test.example.com').returns(false)
    @provider.expects(:dns_find).with('test.example.com').returns(false)
    assert_raise(Proxy::Dns::NotFound) { assert @provider.remove_aaaa_record('test.example.com') }
  end

  # Test PTR record removal
  def test_remove_ptr
    # Use mocha to expect any calls to backend services to prevent deleting real records
    #   MyService.expects(:delete).with(:ip => '10.1.1.1').returns(true)
    @provider.expects(:dns_find).with('10.1.1.1').returns(true)
    assert @provider.remove_ptr_record('10.1.1.1')
  end

  # Test PTR record removal fails if the record doesn't exist
  def test_remove_ptr_not_found
    # Use mocha to expect any calls to backend services to prevent deleting real records
    #   MyService.expects(:delete).with(:ip => '10.1.1.1').returns(false)
    @provider.expects(:dns_find).with('10.1.1.1').returns(false)
    assert_raise(Proxy::Dns::NotFound) { assert @provider.remove_ptr_record('10.1.1.1') }
  end
end
