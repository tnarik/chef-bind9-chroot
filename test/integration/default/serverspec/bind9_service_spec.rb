require 'spec_helper'

describe port(53) do
  it { should be_listening }
end

describe 'check Bind sevice' do
  it 'should enable and run service' do
    case RSpec.configuration.os[:family]
    when 'Ubuntu'
      expect(service('bind9')).to be_enabled
      expect(service('bind9')).to be_running
    else
      expect(service('named')).to be_enabled
      expect(service('named')).to be_running
    end
  end
end

describe 'named.conf.local' do
  it 'should exist' do
    case RSpec.configuration.os[:family]
    when 'Ubuntu'
      expect(file('/etc/bind/named.conf.local')).to be_file
    else
      expect(file('/etc/named/named.conf.local')).to be_file
    end
  end

  it 'should contain correct content' do
    case RSpec.configuration.os[:family]
    when 'Ubuntu'
      expect(file('/etc/bind/named.conf.local').content).to match(
'//
// Do any local configuration here
//

// Consider adding the 1918 zones here, if they are not used in your
// organization
//include "/etc/bind/zones.rfc1918";

zone "example.com" {
  type master;
  file "/etc/bind/zones/db.example.com";
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
  file "db.example.net";
  masters {
    192.168.1.1;
  };
};'
      )
    else
      expect(file('/etc/named/named.conf.local').content).to match(
'//
// Do any local configuration here
//

// Consider adding the 1918 zones here, if they are not used in your
// organization
//include "/etc/bind/zones.rfc1918";

zone "example.com" {
  type master;
  file "/var/named/zones/db.example.com";
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
  file "db.example.net";
  masters {
    192.168.1.1;
  };
};'
      )
    end
  end
end

describe 'db.example.com' do
  it 'should exist' do
    case RSpec.configuration.os[:family]
    when 'Ubuntu'
      expect(file('/etc/bind/zones/db.example.com')).to be_file
    else
      expect(file('/var/named/zones/db.example.com')).to be_file
    end
  end

  it 'should contain correct content' do
    case RSpec.configuration.os[:family]
    when 'Ubuntu'
      expect(file('/etc/bind/zones/db.example.com').content).to match(
'$TTL 300
@ IN SOA ns.example.com. root.example.com. (
                0000 ; serial [yyyyMMddNN]
                4H      ; refresh
                30M     ; retry
                1W      ; expiry
                1D      ; minimum
)

                           IN    NS ns.example.com.
                           IN    NS ns1.example.com.
			   IN    NS ns2.example.com.

                           IN    MX 10 ASPMX.L.GOOGLE.COM.

www                        IN     A 127.0.0.1'
      )
#    else
    end
  end 
end
