require 'spec_helper'

describe 'bind9-chroot::server' do
  let(:chef_run) { ChefSpec::Runner.new.converge(described_recipe) }

  context 'Ubuntu 12.04' do
    let(:chef_run) { ChefSpec::Runner.new(UBUNTU_OPTS).converge(described_recipe) } 
   
    before(:each) do
      stub_search("zones", "*:*").and_return([ {"id"=>"exampleDOTcom"} ])
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

    it 'creates directory /var/log/bind owned by bind user' do
      expect(chef_run).to create_directory('/var/log/bind').with(
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

    it 'does not include bind9-chroot::chroot recipe' do
      expect(chef_run).to_not include_recipe('bind9-chroot::chroot')
    end
    
    it 'does include resolvconf recipe' do
      expect(chef_run).to_not include_recipe('resolvconf')
    end

    it 'includes resolvconf recipe' do
      chef_run.node.set[:bind9][:resolvconf] = true
      chef_run.converge(described_recipe)
      expect(chef_run).to include_recipe('resolvconf')
    end

    it 'creates /etc/bind/named.conf.options' do
      expect(chef_run).to create_template('/etc/bind/named.conf.options').with(
      user: 'bind',
      group: 'bind',
      mode: 0644,
    )
    end

    it 'creates /etc/bind/named.conf' do
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
      expect(chef_run).to create_template('/etc/bind/named.conf').with(
      user: 'bind',
      group: 'bind',
      mode: 0644,
      variables: { :zonefiles => [{"id"=>"exampleDOTcom"}] }
    )
    end

#    it '/etc/bind/named.conf.local notifies bind9 to restart' do
#      expect(chef_run.template('/etc/bind/named.conf.local')).to notify('service[bind9]').to(:restart)
#    end

  end
end
