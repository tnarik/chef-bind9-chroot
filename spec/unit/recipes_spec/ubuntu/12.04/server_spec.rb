require 'spec_helper'

ChefSpec::Coverage.start! do
  add_filter '*/bind9-chroot/recipes/chroot.rb'
end

describe 'bind9-chroot::server' do
  context 'Ubuntu 12.04' do
    let(:chef_run) do 
      ChefSpec::Runner.new(:platform=>'ubuntu',:version=>'12.04') do |node|
        node.set[:bind9][:zones] = Zones
      end.converge(described_recipe)
    end
     
    before(:each) do
      File.stub(:readlines).with(anything).and_call_original
      File.stub(:readlines).with('/etc/init.d/bind9').and_return(['/var/run/named'])
    end 
    
    it "installs bind9" do
      expect(chef_run).to install_package('bind9')
    end

    it "enables bind9 service" do
      expect(chef_run).to enable_service('bind9')
    end

    it "creates directory /var/cache/bind owned by bind user" do
      expect(chef_run).to create_directory('/var/cache/bind').with(
        user: 'bind',
        group: 'bind',
        mode: 0755,
        recursive: true
      )
    end

    it "creates directory /var/run/bind/var/cache/bind owned by bind user" do
      chef_run.node.set[:bind9][:chroot_dir] = '/var/run/bind'
      chef_run.converge(described_recipe)
      expect(chef_run).to create_directory('/var/run/bind/var/cache/bind').with(
        user: 'bind',
        group: 'bind',
        mode: 0755,
        recursive: true
      )
    end

    it "creates directory /var/log/named owned by bind user" do
      expect(chef_run).to create_directory('/var/log/named').with(
        user: 'bind',
        group: 'bind',
        mode: 0755,
        recursive: true
      )
    end

    it "creates directory /var/run/bind/var/log/named owned by bind user" do
      chef_run.node.set[:bind9][:chroot_dir] = '/var/run/bind'
      chef_run.converge(described_recipe)
      expect(chef_run).to create_directory('/var/run/bind/var/log/named').with(
        user: 'bind',
        group: 'bind',
        mode: 0755,
        recursive: true
      )
    end

    it "creates directory /etc/bind/zones owned by bind user" do
      expect(chef_run).to create_directory('/etc/bind/zones').with(
        user: 'bind',
        group: 'bind',
        mode: 0744,
        recursive: true
      )
    end

    it "creates directory /var/run/bind/etc/bind/zones owned by bind user" do
      chef_run.node.set[:bind9][:chroot_dir] = '/var/run/bind'
      chef_run.converge(described_recipe)
      expect(chef_run).to create_directory('/var/run/bind/etc/bind/zones').with(
        user: 'bind',
        group: 'bind',
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

    it "creates template /etc/bind/named.conf.options" do
      expect(chef_run).to create_template('/etc/bind/named.conf.options').with(
        user: 'bind',
        group: 'bind',
        mode: 0644,
      )
    end

    it "creates template /etc/bind/named.conf" do
      expect(chef_run).to create_template('/etc/bind/named.conf').with(
        user: 'bind',
        group: 'bind',
        mode: 0644,
      )
    end

    it "/etc/bind/named.conf notifies bind9 to restart" do
      expect(chef_run.template('/etc/bind/named.conf')).to notify('service[bind9]').to(:restart)
    end

    it "creates /etc/bind/named.conf.local" do
      expect(chef_run).to create_template('/etc/bind/named.conf.local').with(
        user: 'bind',
        group: 'bind',
        mode: 0644,
        variables: { :zonefiles => Zones }
      )
    end

    it "/etc/bind/named.conf.local notifies bind9 to restart" do
      expect(chef_run.template('/etc/bind/named.conf.local')).to notify('service[bind9]').to(:restart)
    end

    it 'creates /etc/default/bind9' do 
      expect(chef_run).to create_template('/etc/default/bind9').with(
        user: 'bind',
        group: 'bind',
        mode: 0644,
      )
    end

    it '/etc/default/bind9 notifies bind9 to restart' do
      expect(chef_run.template('/etc/default/bind9')).to notify('service[bind9]').to(:restart)
    end

    it "does not create /etc/bind/zones/db.example.com" do
      expect(chef_run).to_not create_template('/etc/bind/zones/db.example.com').with(
        source: '/etc/bind/zones/example.com.erb',
        local: true,
        user: 'bind',
        group: 'bind',
        mode: 0644,
        variables: { :serial => '00000' }
      )
    end

    it "creates /etc/bind/zones/db.example.com.erb" do
      expect(chef_run).to create_template('/etc/bind/zones/db.example.com.erb').with(
        source: 'zonefile.erb',
        user: 'bind',
        group: 'bind',
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

    it "notifies /etc/bind/zones/db.example.com immediately" do
      expect(chef_run.template('/etc/bind/zones/db.example.com.erb')).to notify("template[/etc/bind/zones/db.example.com]").to(:create).immediately
    end

    it "does not create /etc/bind/zones/db.example.net.erb" do
      expect(chef_run).to_not create_template('/etc/bind/zones/db.example.net.erb')
    end

  end
end
