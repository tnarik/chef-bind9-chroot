# Cookbook Name:: bind9-chroot
# Recipe:: server
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

directory "#{node[:bind9][:chroot_dir].to_s}#{node[:bind9][:data_path]}" do
  owner node[:bind9][:user]
  group node[:bind9][:user]
  mode 0755
  recursive true
end

log_dir = File.dirname(node[:bind9][:log_file])
directory "#{node[:bind9][:chroot_dir].to_s}#{log_dir}" do
  owner node[:bind9][:user]
  group node[:bind9][:user]
  mode 0755
  recursive true
end

directory "#{node[:bind9][:chroot_dir].to_s}#{node[:bind9][:zones_path]}" do
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
  include_recipe "resolvconf"
 # file "/etc/resolvconf/resolv.conf.d/tail" do
 #   content NameServer.nameserver_proxy("/etc/resolv.conf", /nameserver.*/)
 #   only_if { !::File.exists?("/etc/resolvconf/resolv.conf.d/tail")  }
 # end
end

template "#{node[:bind9][:config_path]}/#{node[:bind9][:options_file]}" do
  source "named.conf.options.erb"
  owner node[:bind9][:user]
  group node[:bind9][:user]
  mode 0644
  notifies :restart, "service[bind9]"
end

template "#{node[:bind9][:config_path]}/#{node[:bind9][:config_file]}" do
  source "named.conf.erb"
  owner node[:bind9][:user]
  group node[:bind9][:user]
  mode 0644
  notifies :restart, "service[bind9]"
end

template "#{node[:bind9][:config_path]}/#{node[:bind9][:local_file]}" do
  source "named.conf.local.erb"
  owner node[:bind9][:user]
  group node[:bind9][:user]
  mode 0644
  variables(
            :zonefiles => node[:bind9][:zones]
           )
  notifies :restart, "service[bind9]"
end

case node[:platform]
when 'ubuntu'
  template node[:bind9][:defaults_file] do
    source "bind9.erb"
    owner node[:bind9][:user]
    group node[:bind9][:user]
    mode 0644
    notifies :restart, "service[bind9]"
    not_if { node[:bind9][:defaults_file].nil? }
  end
end

node[:bind9][:zones].each do |z|
  template "#{node[:bind9][:zones_path]}/#{z[:domain]}" do
    source "#{node[:bind9][:zones_path]}/#{z[:domain]}.erb"
    local true
    owner node[:bind9][:user]
    group node[:bind9][:user]
    mode 0644
    notifies :restart, "service[bind9]"
    variables({
      :serial => z[:zone_info][:serial] || Time.new.strftime("%Y%m%d%H%M%S")
    })
    action :nothing
  end

  template "#{node[:bind9][:zones_path]}/#{z[:domain]}.erb" do
    source "zonefile.erb"
    owner node[:bind9][:user]
    group node[:bind9][:user]
    mode 0644
    variables({
      :soa => z[:zone_info][:soa],
      :contact => z[:zone_info][:contact],
      :global_ttl => z[:zone_info][:global_ttl],
      :nameserver => z[:zone_info][:nameserver],
      :mail_exchange => z[:zone_info][:mail_exchange],
      :records => z[:zone_info][:records]
    })
    notifies :create, "template[#{node[:bind9][:zones_path]}/#{z[:domain]}]", :immediately
  end
end
