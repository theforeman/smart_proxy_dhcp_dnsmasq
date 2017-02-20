# Dnsmasq DHCP Smart Proxy plugin


This plugin adds a new DHCP provider for managing records in dnsmasq.

## Installation

See [How_to_Install_a_Smart-Proxy_Plugin](http://projects.theforeman.org/projects/foreman/wiki/How_to_Install_a_Smart-Proxy_Plugin)
for how to install Smart Proxy plugins

This plugin is compatible with Smart Proxy 1.15 or higher.

## Configuration

To enable this DNS provider, edit `/etc/foreman-proxy/settings.d/dhcp.yml` and set:

    :use_provider: dhcp_dnsmasq

Configuration options for this plugin are in `/etc/foreman-proxy/settings.d/dhcp_dnsmasq.yml` and include:

* `config_files`: The path to the configuration files to load, changes will be written to the last one unless a `write_config_file` is provided.
* `lease_file`: The path to the lease file. (*optional if `dhcp-leasefile` is set in one of the config files*)
* `reload_cmd`: The command to use for reloading the dnsmasq configuration.
* `write_config_file`: The file to write any new changes to, the smart-proxy will only be able to remove any reservations made in this file.

For best results, the write config should point to a file in a dnsmasq `conf-dir` which only the smart-proxy uses.

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

