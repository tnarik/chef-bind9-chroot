require 'spec_helper'

ChefSpec::Coverage.start!

describe 'bind9-chroot::chroot' do
  PLATFORMS.each do |p|
    context "#{p['platform']} #{p['version']}" do
      let(:chef_run) do
        ChefSpec::Runner.new(:platform=>p['platform'],:version=>p['version']) do |node|
          node.set[:bind9][:chroot_dir] = '/var/run/bind'
        end.converge(described_recipe)
      end

      before(:each) do
        File.stub(:readlines).with(anything).and_call_original
        File.stub(:readlines).with('/etc/init.d/bind9').and_return(['/var/run/named'])
        File.stub(:directory?).with(anything).and_call_original
        File.stub(:directory?).with('/var/run/bind/usr/lib/x86_64-linux-gnu/openssl-1.0.0').and_return(true)
      end

    case p['platform']
    when 'ubuntu'
      it 'does not run ruby_block copy_openssl_dependencies when /var/run/bind/usr/lib/x86_64-linux-gnu/openssl-1.0.0 exists' do
        expect(chef_run).to_not run_ruby_block('copy_openssl_dependencies')
      end

      it 'does not run ruby_block copy_openssl_dependencies when /usr/lib/x86_64-linux-gnu/openssl-1.0.0 does not exist' do
        File.stub(:directory?).with('/usr/lib/x86_64-linux-gnu/openssl-1.0.0').and_return(false)
        expect(chef_run).to_not run_ruby_block('copy_openssl_dependencies')
      end

      it 'runs ruby_block copy_openssl_dependencies' do
        File.stub(:directory?).with('/var/run/bind/usr/lib/x86_64-linux-gnu/openssl-1.0.0').and_return(false)
        expect(chef_run).to run_ruby_block('copy_openssl_dependencies')
      end
    end
      

    it 'creates directory /var/run/bind/var/run/named' do
      expect(chef_run).to create_directory('/var/run/bind/var/run/named').with(
        user: p['user'],
        group: p['user'],
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

    it "creates directory /var/run/bind#{p['config_path']}" do
      expect(chef_run).to create_directory("/var/run/bind#{p['config_path']}").with(
        user: p['user'],
        group: p['user'],
        mode: 0744,
        recursive: true
      )
    end

    it 'runs ruby_block move_config_to_chroot' do
      File.stub(:symlink?).with(anything).and_call_original
      File.stub(:symlink?).with(p['config_path']).and_return(false)
      expect(chef_run).to run_ruby_block('move_config_to_chroot')
    end

    it 'does not run ruby_block move_config_to_chroot' do
      File.stub(:symlink?).with(anything).and_call_original
      File.stub(:symlink?).with(p['config_path']).and_return(true)
      expect(chef_run).to_not run_ruby_block('move_config_to_chroot')
    end

    it 'links bind config from chroot' do
      expect(chef_run).to create_link(p['config_path']).with(
        to: "/var/run/bind#{p['config_path']}"
      )
    end

    case p['platform']
    when "ubuntu"
      it "does not create directory /var/run/bind#{p['zone_path']}" do
        expect(chef_run).to_not create_directory("/var/run/bind#{p['zone_path']}")
      end

      it 'does not link bind zones from chroot' do
        expect(chef_run).to_not create_link("#{p['zone_path']}").with(
          to: "/var/run/bind#{p['zone_path']}"
        )
      end
    else
      it "does not create directory /var/run/bind#{p['zone_path']}" do
        expect(chef_run).to create_directory("/var/run/bind#{p['zone_path']}").with(
          user: p['user'],
          group: p['user'],
          mode: 0744,
          recursive: true
        )
      end

      it 'does not link bind zones from chroot' do
        expect(chef_run).to create_link("#{p['zone_path']}").with(
          to: "/var/run/bind#{p['zone_path']}"
        )
      end
    end  

    it 'creates directory /var/run/bind/dev' do
      expect(chef_run).to create_directory('/var/run/bind/dev').with(
        user: p['user'],
        group: p['user'],
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
end

