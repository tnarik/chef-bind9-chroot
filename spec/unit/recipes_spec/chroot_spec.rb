require 'spec_helper'

describe 'bind9-chroot::chroot' do
  
  context 'Ubuntu 12.04' do
    let(:chef_run) do
      ChefSpec::Runner.new(UBUNTU_OPTS) do |node|
        node.set[:bind9][:chroot_dir] = '/var/run/bind'
      end.converge(described_recipe)
    end

    before(:each) do
      File.stub(:readlines).with(anything).and_call_original
      File.stub(:readlines).with('/etc/init.d/bind9').and_return(['/var/run/named'])
    end

    it 'does not run ruby_block copy_openssl_dependencies when /var/run/bind/usr/lib/x86_64-linux-gnu/openssl-1.0.0 exists' do
      File.stub(:directory?).with(anything).and_call_original
      File.stub(:directory?).with('/var/run/bind/usr/lib/x86_64-linux-gnu/openssl-1.0.0').and_return(true)
      expect(chef_run).to_not run_ruby_block('copy_openssl_dependencies')
    end

    it 'does not run ruby_block copy_openssl_dependencies when /var/run/bind does not exists' do
      File.stub(:directory?).with(anything).and_call_original
      File.stub(:directory?).with('/usr/lib/x86_64-linux-gnu/openssl-1.0.0').and_return(false)
      expect(chef_run).to_not run_ruby_block('copy_openssl_dependencies')
    end

    it 'runs ruby_block copy_openssl_dependencies' do
      expect(chef_run).to run_ruby_block('copy_openssl_dependencies')
    end

    it 'creates directory /var/run/bind/var/run/named' do
      expect(chef_run).to create_directory('/var/run/bind/var/run/named').with(
        user: 'bind',
        group: 'bind',
        mode: 0744,
        recursive: true
      )
    end
 
    it 'runs ruby_block modify_init_script' do
      expect(chef_run).to run_ruby_block('modify_init_script')
    end

    it 'does not run ruby_block modify_init_script' do
      File.stub(:readlines).with(anything).and_call_original
      File.stub(:readlines).with('/etc/init.d/bind9').and_return([''])
      expect(chef_run).to_not run_ruby_block('modify_init_script')
    end

    it 'creates directory /var/run/bind/etc/bind' do
      expect(chef_run).to create_directory('/var/run/bind/etc/bind').with(
        user: 'bind',
        group: 'bind',
        mode: 0744,
        recursive: true
      )
    end

    it 'runs ruby_block move_config_to_chroot' do
      expect(chef_run).to run_ruby_block('move_config_to_chroot')
    end

    it 'links bind config from chroot' do
      expect(chef_run).to create_link('/etc/bind').with(to: '/var/run/bind/etc/bind')
    end

    it 'does not create directory /var/run/bind/etc/bind/zones' do
      expect(chef_run).to_not create_directory('/var/run/bind/etc/bind/zones').with(
        user: 'bind',
        group: 'bind',
        mode: 0744,
        recursive: true
      )
    end

    it 'does not link bind zones from chroot' do
      expect(chef_run).to_not create_link('/etc/bind/zones').with(to: '/var/run/bind/etc/bind/zones')
    end

    it 'creates directory /var/run/bind/dev' do
      expect(chef_run).to create_directory('/var/run/bind/dev').with(
        user: 'bind',
        group: 'bind',
        mode: 0744,
        recursive: true
      )
    end

    it 'creates special device files' do
      expect(chef_run).to run_execute('create_special_device_files')
    end

    it 'does not create special device files' do
      File.stub(:exists?).with(anything).and_call_original
      File.stub(:exists?).with('/var/run/bind/dev/null').and_return(true)
      expect(chef_run).to_not run_execute('create_special_device_files')
    end

  end
end
