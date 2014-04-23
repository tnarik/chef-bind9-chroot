require 'spec_helper'

ChefSpec::Coverage.start! do
  add_filter '*/bind9-chroot/recipes/chroot.rb'
end

describe 'bind9-chroot::server' do
  context 'Centos 6.5' do
    let(:chef_run) do 
      ChefSpec::Runner.new(:platform=>'centos',:version=>'6.5') do |node|
        node.set[:bind9][:zones] = zones
      end.converge(described_recipe)
    end
    let(:zones) {
      [
        {
          'domain' => 'example.com',
          'zone_info' => {
            'serial' =>'00000',
            'soa' => 'ns.example.com',
            'contact' => 'root.example.com',
            'global_ttl' => 300,
            'nameserver' => [
              'ns1.example.com',
              'ns2.example.com'
            ],
            'mail_exchange' => [
              {
                'host' => 'ASPMX.L.GOOGLE.COM.',
                'priority' => 10,
              }
            ],
            'records' => [
              {
                'name' => 'www',
                'type' => 'A',
                'ip' => '127.0.0.1'
              }
            ]    
          }
        }
      ]
    }
     
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

    it "creates /etc/named/named.conf.local" do
      expect(chef_run).to create_template('/etc/named/named.conf.local').with(
        user: 'named',
        group: 'named',
        mode: 0644,
        variables: { :zonefiles => zones }
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

    it "does not create /var/named/zones/example.com" do
      expect(chef_run).to_not create_template('/var/named/zones/example.com').with(
        source: '/var/named/zones/example.com.erb',
        local: true,
        user: 'named',
        group: 'named',
        mode: 0644,
        variables: { :serial => '00000' }
      )
    end

    it "creates /var/named/zones/example.com.erb" do
      expect(chef_run).to create_template('/var/named/zones/example.com.erb').with(
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

    it "notifies /var/named/zones/example.com immediately" do
      expect(chef_run.template('/var/named/zones/example.com.erb')).to notify("template[/var/named/zones/example.com]").to(:create).immediately
    end

  end
end
