require 'test_helper'
require 'smart_proxy_dns_plugin_template/dns_plugin_template_configuration'
require 'smart_proxy_dns_plugin_template/dns_plugin_template_plugin'

class DnsPluginTemplateDefaultSettingsTest < Test::Unit::TestCase
  def test_default_settings
    Proxy::Dns::PluginTemplate::Plugin.load_test_settings({})
    assert_equal "default_value", Proxy::Dns::PluginTemplate::Plugin.settings.required_setting
    assert_equal "/must/exist", Proxy::Dns::PluginTemplate::Plugin.settings.required_path
  end
end
