# Cookbook Name:: bind9-reversezones
# Recipe:: reversezones
#
# Copyright 2013, Arnold Krille
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


directory node[:bind9][:zones_path] do
  owner node[:bind9][:user]
  group node[:bind9][:user]
  mode  0744
  recursive true
  not_if { ::File.directory?(node[:bind9][:zones_path]) or ::File.symlink?(node[:bind9][:zones_path]) }
end

search(:reversezones).each do |zone|
  unless zone['autodomain'].nil? || zone['autodomain'] == ''
    zoneip = zone['domain'].scan(/[0-9]+/).join('.')
    search(:node, "ipaddress:#{zone['autodomain']}*").each do |host|
      next if host['ipaddress'] == '' || host['ipaddress'].nil?
      zone['zone_info']['records'].push( {
        "name" => host['fqdn'] or "#{host['name']}.#{host['domain']}",
        "type" => "PTR",
        "ip" => host['ipaddress'].scan(/[0-9]{1,3}/).reverse().join('.').sub!(/\.#{zoneip}$/, '')
      })
    end
  end
  if not zone['domain'].end_with?('.IN-ADDR.ARPA')
    zone['domain'] += '.IN-ADDR.ARPA'
  end

  template File.join(node[:bind9][:zones_path], zone['domain']) do
    source File.join(node[:bind9][:zones_path], "#{zone['domain']}.erb")
    local true
    owner node[:bind9][:user]
    group node[:bind9][:user]
    mode 0644
    notifies :restart, "service[bind9]"
    variables({
      :serial => zone['zone_info']['serial'] || Time.new.strftime("%Y%m%d%H%M%S")
    })
    action :nothing
  end

  template File.join(node[:bind9][:zones_path], "#{zone['domain']}.erb") do
    source "reverse_zonefile.erb"
    owner node[:bind9][:user]
    group node[:bind9][:user]
    mode 0644
    variables({
      :domain => zone['domain'],
      :soa => zone['zone_info']['soa'],
      :contact => zone['zone_info']['contact'],
      :global_ttl => zone['zone_info']['global_ttl'],
      :nameserver => zone['zone_info']['nameserver'],
      :mail_exchange => zone['zone_info']['mail_exchange'],
      :records => zone['zone_info']['records']
    })
    notifies :create, resources(:template => File.join(node[:bind9][:zones_path], zone['domain'])), :immediately
  end
end
