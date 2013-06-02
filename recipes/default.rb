# Cookbook Name:: bind9-chroot
# Recipe:: default
#
# Copyright 2011, Mike Adolphs
# Copyright 2013, tnarik
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

package "bind9" do
  case node[:platform]
  when "centos", "redhat", "suse", "fedora"
    package_name "bind"
  end
  action :install
end

service "bind9" do
  case node[:platform]
  when "centos", "redhat"
    service_name "named"
  end
  supports :status => true, :reload => true, :restart => true
  action [ :enable ]
end

directory File.join(node[:bind9][:chroot_dir].to_s, node[:bind9][:data_path]) do
  owner node[:bind9][:user]
  group node[:bind9][:user]
  mode 0755
  recursive true
end

directory File.dirname(File.join(node[:bind9][:chroot_dir].to_s, node[:bind9][:log_file])) do
  owner node[:bind9][:user]
  group node[:bind9][:user]
  mode 0755
  recursive true
end

directory File.join(node[:bind9][:chroot_dir].to_s, node[:bind9][:zones_path]) do
  owner node[:bind9][:user]
  group node[:bind9][:user]
  mode 0744
  recursive true
end

if !node[:bind9][:chroot_dir].nil?
  include_recipe "bind9-chroot::chroot"
end

class Chef::Recipe::NameServer
  include LeCafeAutomatique::Bind9::NameServer
end

if node[:bind9][:resolvconf]
  file "/etc/resolvconf/resolv.conf.d/tail" do
    content NameServer.nameserver_proxy("/etc/resolv.conf", /nameserver.*/)
    only_if { !::File.exists?("/etc/resolvconf/resolv.conf.d/tail")  }
  end
end


template File.join(node[:bind9][:config_path], node[:bind9][:options_file]) do
  source "named.conf.options.erb"
  owner node[:bind9][:user]
  group node[:bind9][:user]
  mode 0644
  notifies :restart, "service[bind9]"
end

template File.join(node[:bind9][:config_path], node[:bind9][:config_file]) do
  source "named.conf.erb"
  owner node[:bind9][:user]
  group node[:bind9][:user]
  mode 0644
  notifies :restart, "service[bind9]"
end

template File.join(node[:bind9][:config_path], node[:bind9][:local_file]) do
  source "named.conf.local.erb"
  owner node[:bind9][:user]
  group node[:bind9][:user]
  mode 0644
  variables({
    :zonefiles => search(:zones)
  })
  notifies :restart, "service[bind9]"
end


template node[:bind9][:defaults_file] do
  source "bind9.erb"
  owner node[:bind9][:user]
  group node[:bind9][:user]
  mode 0644
  notifies :restart, "service[bind9]"
  not_if { node[:bind9][:defaults_file].nil? }
end


directory node[:bind9][:zones_path] do
  owner node[:bind9][:user]
  group node[:bind9][:user]
  mode  0744
  recursive true
  not_if { ::File.directory?(node[:bind9][:zones_path]) or ::File.symlink?(node[:bind9][:zones_path]) }
end

search(:zones).each do |zone|
  #unless zone['autodomain'].nil? || zone['autodomain'] == ''
  #  search(:node, "domain:#{zone['autodomain']}").each do |host|
  #    next if host['ipaddress'] == '' || host['ipaddress'].nil?
  #    zone['zone_info']['records'].push( {
  #      "name" => host['hostname'],
  #      "type" => "A",
  #      "ip" => host['ipaddress']
  #    })
  #  end
  #end

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
    source "zonefile.erb"
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

service "bind9" do
  action [ :start ]
end
