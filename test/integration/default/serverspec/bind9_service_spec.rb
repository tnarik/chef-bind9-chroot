require 'spec_helper'

describe port(53) do
  it { should be_listening }
end

case RSpec.configure.os[:family]
when 'Ubuntu'

  describe package('bind9') do
    it { should be_installed }
  end

  describe service('bind9') do
    it { should be_enabled }
    it { should be_running }
  end

  describe file('/etc/bind/named.conf.local') do
    contents = '//
// Do any local configuration here
//

// Consider adding the 1918 zones here, if they are not used in your
// organization
//include "/etc/bind/zones.rfc1918";

zone "example.com" {
  type master;
  file "/etc/bind/zones/example.com";
  allow-transfer {
    192.168.1.2;
    192.168.1.3;
  };
  also-notify {
    192.168.1.2;
    192.168.1.3;
  };
};

zone "example.net" {
  type slave;
  file "example.net";
  masters {
    192.168.1.1;
  };
};'
    it { should be_file }
    its(:content) {should match contents }
  end

  describe file('/etc/bind/zones/example.com') do
    contents = '\$TTL 300
@ IN SOA ns.example.com. root.example.com. \(
                00000 \; serial \[yyyyMMddNN\]
                4H      \; refresh
                30M     \; retry
                1W      \; expiry
                1D      \; minimum
\)

                           IN    NS ns.example.com.
                           IN    NS ns1.example.com.
                           IN    NS ns2.example.com.

                           IN    MX 10 ASPMX.L.GOOGLE.COM.

www                        IN     A 127.0.0.1'

    it { should be_file }
    its(:content) { should match contents }
  end

else

  describe package('bind') do
    it { should be_installed }
  end

  describe service('named') do
    it { should be_enabled }
    it { should be_running }
  end

  describe file('/etc/named/named.conf.local') do
    contents = '//
// Do any local configuration here
//

// Consider adding the 1918 zones here, if they are not used in your
// organization
//include "/etc/bind/zones.rfc1918";

zone "example.com" {
  type master;
  file "/var/named/zones/example.com";
  allow-transfer {
    192.168.1.2;
    192.168.1.3;
  };
  also-notify {
    192.168.1.2;
    192.168.1.3;
  };
};

zone "example.net" {
  type slave;
  file "example.net";
  masters {
    192.168.1.1;
  };
};'
    it { should be_file }
    its(:content) {should match contents }
  end

  describe file('/var/named/zones/example.com') do
    content = '\$TTL 300
@ IN SOA ns.example.com. root.example.com. \(
                00000 \; serial \[yyyyMMddNN\]
                4H      \; refresh
                30M     \; retry
                1W      \; expiry
                1D      \; minimum
\)

                           IN    NS ns.example.com.
                           IN    NS ns1.example.com.
                           IN    NS ns2.example.com.

                           IN    MX 10 ASPMX.L.GOOGLE.COM.

www                        IN     A 127.0.0.1'
    it { should be_file }
    its(:content) { should match content }
  end

end
