default[:bind9][:enable_ipv6] = true

# Allow all clients to query the nameserver, no recursion
default[:bind9][:allow_query] = nil
default[:bind9][:allow_recursion] = "none"

# Don:t allow to mess with zone files by default
default[:bind9][:allow_transfer] = "none"
default[:bind9][:allow_update] = nil

default[:bind9][:enable_forwarding] = false
default[:bind9][:forwarders] = [ "8.8.4.4", "8.8.8.8" ]
default[:bind9][:resolvconf] = false
default[:bind9][:chroot_dir] = nil
default[:bind9][:disclose] = false

default[:bind9][:pidfile] = "/var/run/named/named.pid"

case platform
when "centos","redhat","fedora","scientific","amazon"
  default[:bind9][:config_path] = "/etc/named"
  default[:bind9][:config_file] = "named.conf"
  default[:bind9][:options_file] = "named.conf.options"
  default[:bind9][:local_file] = "named.conf.local"
  default[:bind9][:data_path] = "/var/named"
  default[:bind9][:zones_path] = "/var/named/zones"
  default[:bind9][:log_file] = "/var/log/named/named.log"
  default[:bind9][:user] = "named"
else
  default[:bind9][:config_path] = "/etc/bind"
  default[:bind9][:config_file] = "named.conf"
  default[:bind9][:options_file] = "named.conf.options"
  default[:bind9][:local_file] = "named.conf.local"
  default[:bind9][:defaults_file] = "/etc/default/bind9"
  default[:bind9][:data_path] = "/var/cache/bind"
  default[:bind9][:zones_path] = "/etc/bind/zones"
  default[:bind9][:log_file] = "/var/log/bind/bind.log"
  default[:bind9][:user] = "bind"
  
  default[:bind9][:openssl] = "/usr/lib/x86_64-linux-gnu/openssl-1.0.0"
end
