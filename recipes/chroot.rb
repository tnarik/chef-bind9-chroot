# Cookbook Name:: bind9-chroot
# Recipe:: chroot
#
# Copyright 2013, Tnarik Innael
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

case node[:platform]
  when "ubuntu"
    if node[:platform_version].to_f >= 12.04
      ruby_block "copy_openssl_dependencies" do
        block do
          FileUtils.mkdir_p File.dirname(File.join(node[:bind9][:chroot_dir], node[:bind9][:openssl]))
          FileUtils.cp_r node[:bind9][:openssl], File.dirname(File.join(node[:bind9][:chroot_dir], node[:bind9][:openssl]))
        end
        not_if { ::File.directory?(File.join(node[:bind9][:chroot_dir], node[:bind9][:openssl])) or
                  !::File.directory?(node[:bind9][:openssl]) }
      end
    end
end

directory File.join(node[:bind9][:chroot_dir].to_s, "/var/run/named") do
  owner node[:bind9][:user]
  group node[:bind9][:user]
  mode  0744
  recursive true
  not_if { ::File.directory?(File.join(node[:bind9][:chroot_dir].to_s, "/var/run/named")) }
end

ruby_block "modify_init_script" do
  block do
    rc = Chef::Util::FileEdit.new("/etc/init.d/bind9")
    rc.search_file_replace(Regexp.new("/var/run/named"), "${PIDDIR}")
    rc.write_file
  end
  not_if { ::File.readlines('/etc/init.d/bind9').grep(Regexp.new("/var/run/named")).empty? }
end

chroot_config_dir = File.join(node[:bind9][:chroot_dir].to_s, node[:bind9][:config_path])

directory chroot_config_dir do
  owner node[:bind9][:user]
  group node[:bind9][:user]
  mode  0744
  recursive true
end

ruby_block "move_config_to_chroot" do
  block do
    FileUtils.rm_rf chroot_config_dir
    FileUtils.mv node[:bind9][:config_path], chroot_config_dir
  end
  not_if { ::File.symlink?(node[:bind9][:config_path]) }
end

directory chroot_config_dir do
  owner node[:bind9][:user]
  group node[:bind9][:user]
  mode 0744
  recursive true
end

link "bind_config_from_chroot" do
  target_file node[:bind9][:config_path]
  to chroot_config_dir
  not_if { ::File.symlink?(node[:bind9][:config_path]) }
end

chroot_zones_dir = File.join(node[:bind9][:chroot_dir].to_s, node[:bind9][:zones_path])

directory chroot_zones_dir do
  owner node[:bind9][:user]
  group node[:bind9][:user]
  mode  0744
  recursive true
  not_if { chroot_zones_dir.start_with?(chroot_config_dir)  }
end

link "bind_zones_from_chroot" do
  target_file node[:bind9][:zones_path]
  to chroot_zones_dir
  not_if { ::File.symlink?(node[:bind9][:zones_path]) or chroot_zones_dir.start_with?(chroot_config_dir)  }
end

directory File.join(node[:bind9][:chroot_dir].to_s, "/dev") do
  owner node[:bind9][:user]
  group node[:bind9][:user]
  mode  0744
  recursive true
end

execute "create_special_device_files" do
  command "mknod #{node[:bind9][:chroot_dir]}/dev/null c 1 3;
            mknod #{node[:bind9][:chroot_dir]}/dev/random c 1 8;
            chmod 666 #{node[:bind9][:chroot_dir]}/dev/null;
            chmod 666 #{node[:bind9][:chroot_dir]}/dev/random"
  not_if { ::File.exists?( File.join(node[:bind9][:chroot_dir].to_s, "/dev/null")) }
end
