require 'spec_helper'

ChefSpec::Coverage.start! do
  add_filter '*/bind9-chroot/recipes/chroot.rb'
end

describe 'bind9-chroot::server' do
  context 'Centos 6.5' do
    let(:chef_run) do 
      ChefSpec::Runner.new(:platform=>'centos',:version=>'6.5') do |node|
        node.set[:bind9][:zones] = Zones
      end.converge(described_recipe)
    end
    
     
    before(:each) do
      File.stub(:readlines).with(anything).and_call_original
      File.stub(:readlines).with('/etc/init.d/bind9').and_return(['/var/run/named'])
    end 
    
    it "installs bind" do
      expect(chef_run).to install_package('bind')
    end

    it "enables named service" do
      expect(chef_run).to enable_service('named')
    end

    it "creates directory /var/named owned by named user" do
      expect(chef_run).to create_directory('/var/named').with(
        user: 'named',
        group: 'named',
        mode: 0755,
        recursive: true
      )
    end

    it "creates directory /var/run/bind/var/named owned by named user" do
      chef_run.node.set[:bind9][:chroot_dir] = '/var/run/bind'
      chef_run.converge(described_recipe)
      expect(chef_run).to create_directory('/var/run/bind/var/named').with(
        user: 'named',
        group: 'named',
        mode: 0755,
        recursive: true
      )
    end

    it "creates directory /var/log/named owned by named user" do
      expect(chef_run).to create_directory('/var/log/named').with(
        user: 'named',
        group: 'named',
        mode: 0755,
        recursive: true
      )
    end

    it "creates directory /var/run/bind/var/log/named owned by named user" do
      chef_run.node.set[:bind9][:chroot_dir] = '/var/run/bind'
      chef_run.converge(described_recipe)
      expect(chef_run).to create_directory('/var/run/bind/var/log/named').with(
        user: 'named',
        group: 'named',
        mode: 0755,
        recursive: true
      )
    end

    it "creates directory /var/named/zones owned by named user" do
      expect(chef_run).to create_directory('/var/named/zones').with(
        user: 'named',
        group: 'named',
        mode: 0744,
        recursive: true
      )
    end

    it "creates directory /var/run/bind/var/named/zones owned by named user" do
      chef_run.node.set[:bind9][:chroot_dir] = '/var/run/bind'
      chef_run.converge(described_recipe)
      expect(chef_run).to create_directory('/var/run/bind/var/named/zones').with(
        user: 'named',
        group: 'named',
        mode: 0744,
        recursive: true
      )
    end

    it 'does not include bind9-chroot::chroot recipe' do
      expect(chef_run).to_not include_recipe('bind9-chroot::chroot')
    end

    it 'includes bind9-chroot::chroot recipe' do
      chef_run.node.set[:bind9][:chroot_dir] = '/var/run/bind'
      chef_run.converge(described_recipe)
      expect(chef_run).to include_recipe('bind9-chroot::chroot')
    end
   

    it 'does not include resolvconf recipe' do
      expect(chef_run).to_not include_recipe('resolvconf')
    end

    it 'includes resolvconf recipe' do
      chef_run.node.set[:bind9][:resolvconf] = true
      chef_run.converge(described_recipe)
      expect(chef_run).to include_recipe('resolvconf')
    end

    it "creates template /etc/named/named.conf.options" do
      expect(chef_run).to create_template('/etc/named/named.conf.options').with(
        user: 'named',
        group: 'named',
        mode: 0644,
      )
    end

    it "creates template /etc/named/named.conf" do
      expect(chef_run).to create_template('/etc/named/named.conf').with(
        user: 'named',
        group: 'named',
        mode: 0644,
      )
    end

    it "/etc/named/named.conf notifies bind to restart" do
      expect(chef_run.template('/etc/named/named.conf')).to notify('service[named]').to(:restart)
    end

    it "creates /etc/named/named.conf.local owned by named user" do
      expect(chef_run).to create_template('/etc/named/named.conf.local').with(
        user: 'named',
        group: 'named',
        mode: 0644,
        variables: { :zonefiles => Zones }
      )
    end

    it 'fills /etc/named/named.conf.local with correct content' do
      expect(chef_run).to render_file('/etc/named/named.conf.local').with_content(
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

    it "/etc/named/named.conf.local notifies bind to restart" do
      expect(chef_run.template('/etc/named/named.conf.local')).to notify('service[named]').to(:restart)
    end
 
    it "creates directory /var/named/zones owned by named user" do
      expect(chef_run).to create_directory('/var/named/zones').with(
        user: 'named',
        group: 'named',
        mode: 0744,
        recursive: true
      )
    end  

    it "does not create /var/named/zones/db.example.com" do
      expect(chef_run).to_not create_template('/var/named/zones/db.example.com').with(
        source: '/var/named/zones/example.com.erb',
        local: true,
        user: 'named',
        group: 'named',
        mode: 0644,
        variables: { :serial => '00000' }
      )
    end

    it "creates /var/named/zones/db.example.com.erb" do
      expect(chef_run).to create_template('/var/named/zones/db.example.com.erb').with(
        source: 'zonefile.erb',
        user: 'named',
        group: 'named',
        mode: 0644,
        variables: { 
          :soa => 'ns.example.com',
          :contact => 'root.example.com',
          :global_ttl => 300,
          :nameserver => [
            'ns1.example.com',
            'ns2.example.com'
         ],
          :mail_exchange => [
            {
              'host' => 'ASPMX.L.GOOGLE.COM.',
              'priority' => 10
            }
          ],
          :records => [
            {
              'name' => 'www',
              'type' => 'A',
              'ip' => '127.0.0.1'
            }
          ] 
        }
      )
    end

    it 'fills /var/named/zones/db.example.com.erb with correct content' do
      expect(chef_run).to render_file('/var/named/zones/db.example.com.erb').with_content(
'$TTL 300
@ IN SOA ns.example.com root.example.com (
                <%= @serial %> ; serial [yyyyMMddNN]
                4H      ; refresh
                30M     ; retry
                1W      ; expiry
                1D      ; minimum
)

                           IN    NS ns.example.com
                           IN    NS ns1.example.com
                           IN    NS ns2.example.com

                           IN    MX 10 ASPMX.L.GOOGLE.COM.

www                        IN     A 127.0.0.1
' 
      )
    end

    it "notifies /var/named/zones/db.example.com immediately" do
      expect(chef_run.template('/var/named/zones/db.example.com.erb')).to notify("template[/var/named/zones/db.example.com]").to(:create).immediately
    end

    it "does not create /var/named/zones/db.example.net.erb" do
      expect(chef_run).to_not create_template('/var/named/zones/db.example.net.erb')
    end

  end
end
