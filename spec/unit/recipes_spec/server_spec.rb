require 'spec_helper'

describe 'bind9-chroot::server' do
  let(:chef_run) { ChefSpec::Runner.new.converge(described_recipe) }

  context 'Ubuntu 12.04' do
    let(:chef_run) { ChefSpec::Runner.new(UBUNTU_OPTS).converge(described_recipe) }
    let(:zones) {
        [
          {
            'id' => 'exampleDOTcom',
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
      stub_search("zones", "*:*").and_return(zones)
      chef_run.node.set[:bind9][:chroot_dir] = nil
      chef_run.converge(described_recipe)
    end

    it 'installs bind9' do
      expect(chef_run).to install_package('bind9')
    end

    it 'enables bind9 service' do
      expect(chef_run).to enable_service('bind9')
    end

    it 'creates directory /var/cache/bind owned by bind user' do
      expect(chef_run).to create_directory('/var/cache/bind').with(
        user: 'bind',
        group: 'bind',
        mode: 0755,
        recursive: true
      )
    end

    it 'creates directory /var/run/bind/var/cache/bind owned by bind user' do
      chef_run.node.set[:bind9][:chroot_dir] = '/var/run/bind'
      chef_run.converge(described_recipe)
      expect(chef_run).to create_directory('/var/run/bind/var/cache/bind').with(
        user: 'bind',
        group: 'bind',
        mode: 0755,
        recursive: true
      )
    end


    it 'creates directory /var/log/bind owned by bind user' do
      expect(chef_run).to create_directory('/var/log/bind').with(
        user: 'bind',
        group: 'bind',
        mode: 0755,
        recursive: true
      )
    end

    it 'creates directory /var/run/bind/var/log/bind owned by bind user' do
#      chef_run.node.set[:bind9][:chroot_dir] = '/var/run/bind'
#      chef_run.converge(described_recipe)
      expect(chef_run).to create_directory('/var/run/bind/var/log/bind').with(
        user: 'bind',
        group: 'bind',
        mode: 0755,
        recursive: true
      )
    end

    it 'creates directory /etc/bind/zones owned by bind user' do
      expect(chef_run).to create_directory('/etc/bind/zones').with(
        user: 'bind',
        group: 'bind',
        mode: 0744,
        recursive: true
      )
    end

    it 'creates directory /var/run/bind/etc/bind/zones owned by bind user' do
#      chef_run.node.set[:bind9][:chroot_dir] = '/var/run/bind'
#      chef_run.converge(described_recipe)
      expect(chef_run).to create_directory('/var/run/bind/etc/bind/zones').with(
        user: 'bind',
        group: 'bind',
        mode: 0744,
        recursive: true
      )
    end

#    it 'includes bind9-chroot::chroot recipe' do
#      chef_run.node.set[:bind9][:chroot_dir] = '/var/run/bind'
#      chef_run.converge(described_recipe)
#      expect(chef_run).to include_recipe('bind9-chroot::chroot')
#    end
    
#    it 'does not include resolvconf recipe' do
#      expect(chef_run).to_not include_recipe('resolvconf')
#    end

    it 'does include resolvconf recipe' do
      chef_run.node.set[:bind9][:resolvconf] = true
      chef_run.converge(described_recipe)
      expect(chef_run).to include_recipe('resolvconf')
    end

    it 'includes resolvconf recipe' do
      chef_run.node.set[:bind9][:resolvconf] = true
      chef_run.converge(described_recipe)
      expect(chef_run).to include_recipe('resolvconf')
    end

    it 'creates template /etc/bind/named.conf.options' do
      expect(chef_run).to create_template('/etc/bind/named.conf.options').with(
        user: 'bind',
        group: 'bind',
        mode: 0644,
      )
    end

    it 'creates template /etc/bind/named.conf' do
      expect(chef_run).to create_template('/etc/bind/named.conf').with(
        user: 'bind',
        group: 'bind',
        mode: 0644,
      )
    end

    it '/etc/bind/named.conf notifies bind9 to restart' do
      expect(chef_run.template('/etc/bind/named.conf')).to notify('service[bind9]').to(:restart)
    end

    it 'creates /etc/bind/named.conf.local' do
      expect(chef_run).to create_template('/etc/bind/named.conf.local').with(
        user: 'bind',
        group: 'bind',
        mode: 0644,
        variables: { :zonefiles => zones }
      )
    end

    it '/etc/bind/named.conf.local notifies bind9 to restart' do
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

    it 'does not create /etc/bind/zones/example.com' do
      expect(chef_run).to_not create_template('/etc/bind/zones/example.com').with(
        source: '/etc/bind/zones/example.com.erb',
        local: true,
        user: 'bind',
        group: 'bind',
        mode: 0644,
        variables: { :serial => '00000' }
      )
    end

    it 'creates /etc/bind/zones/example.com.erb' do
      expect(chef_run).to create_template('/etc/bind/zones/example.com.erb').with(
        source: 'zonefile.erb',
        user: 'bind',
        group: 'bind',
        mode: 0644,
        variables: { 
          :domain => 'example.com',
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

    it 'notifies /etc/bind/zones/example.com immediately' do
      expect(chef_run.template('/etc/bind/zones/example.com.erb')).to notify('template[/etc/bind/zones/example.com]').to(:create).immediately
    end

    it 'starts bind9 service' do
      expect(chef_run).to start_service('bind9')
    end

  end
end
