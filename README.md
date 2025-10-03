# Dnsmasq DHCP Smart Proxy plugin


This plugin adds a new DHCP provider for managing records in dnsmasq.

## Installation

See [How_to_Install_a_Smart-Proxy_Plugin](http://projects.theforeman.org/projects/foreman/wiki/How_to_Install_a_Smart-Proxy_Plugin)
for how to install Smart Proxy plugins

This plugin is compatible with Smart Proxy 1.17 or higher.

You need to add two lines to your dnsmasq configuration to use this plugin;
```
dhcp-optsfile=<target_dir>/dhcpopts.conf
dhcp-hostsfile=<target_dir>/dhcphosts
```

Dnsmasq will also require write privileges to the configuration file and folder specified.

## Configuration

To enable this DNS provider, edit `/etc/foreman-proxy/settings.d/dhcp.yml` and set:

    :use_provider: dhcp_dnsmasq

Configuration options for this plugin are in `/etc/foreman-proxy/settings.d/dhcp_dnsmasq.yml` and include:

* `config`: The path to the configuration directory to load, changes will be written to host-specific configuration files inside
* `target_dir`: The path of where dhcp files should be written, must have write permissions for the proxy user.
* `lease_file`: The path to the lease file. (*optional, will be auto-discovered if `dhcp-leasefile` is set in one of the config files*)
* `reload_cmd`: The command to use for reloading the dnsmasq configuration.

For best results, the write config should point to a file in a dnsmasq `conf-dir` which only the smart-proxy uses.

### dnsmasq.conf Notes

Whilst dnsmasq can support a variety of formats of several of the parameters in dnsmasq.conf the plugin currently only supports specific versions of those formats;
* `dhcp-range`: MUST include the netmask, e.g. &lt;start address&gt;,&lt;end address&gt;,&lt;netmask&gt;,&lt;ttl&gt; (**NOTE:** the plugin only supports a single subnet currently).
* `dhcp-host`: MUST be in &lt;MAC&gt;,&lt;IP&gt;,&lt;hostname&gt;,&lt;ttl(*optional*)&gt; format, this differs from the example provided in the currently distributed default dnsmasq.conf which has hostname before IP but dnsmasq has no issue with the alternate field ordering (**NOTE:** the plugin does NOT handle the use of DHCP client IDs currently).

## Contributing

Fork and send a Pull Request. Thanks!

## Copyright

Copyright (c) 2017 Alexander Olofsson

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

