require 'spec_helper'

ChefSpec::Coverage.start!

describe 'bind9-chroot::chroot' do
  context 'Centos 6.5' do
    let(:chef_run) do
      ChefSpec::Runner.new(:platform=>'centos',:version=>'6.5') do |node|
        node.set[:bind9][:chroot_dir] = '/var/run/bind'
      end.converge(described_recipe)
    end

    before(:each) do
      File.stub(:readlines).with(anything).and_call_original
      File.stub(:readlines).with('/etc/init.d/bind9').and_return(['/var/run/named'])
      File.stub(:directory?).with(anything).and_call_original
      File.stub(:directory?).with('/var/run/bind/usr/lib/x86_64-linux-gnu/openssl-1.0.0').and_return(true)
    end

    it 'creates directory /var/run/bind/var/run/named' do
      expect(chef_run).to create_directory('/var/run/bind/var/run/named').with(
        user: 'named',
        group: 'named',
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

    it "creates directory /var/run/bind/etc/named" do
      expect(chef_run).to create_directory("/var/run/bind/etc/named").with(
        user: 'named',
        group: 'named',
        mode: 0744,
        recursive: true
      )
    end

    it 'runs ruby_block move_config_to_chroot' do
      File.stub(:symlink?).with(anything).and_call_original
      File.stub(:symlink?).with('/etc/named').and_return(false)
      expect(chef_run).to run_ruby_block('move_config_to_chroot')
    end

    it 'does not run ruby_block move_config_to_chroot' do
      File.stub(:symlink?).with(anything).and_call_original
      File.stub(:symlink?).with('/etc/named').and_return(true)
      expect(chef_run).to_not run_ruby_block('move_config_to_chroot')
    end

    it 'links bind config from chroot' do
      expect(chef_run).to create_link('/etc/named').with(
        to: "/var/run/bind/etc/named"
      )
    end

    it 'creates directory /var/run/bind/dev' do
      expect(chef_run).to create_directory('/var/run/bind/dev').with(
        user: 'named',
        group: 'named',
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

