require 'spec_helper'

ChefSpec::Coverage.start!

describe 'bind9-chroot::chroot' do
  platforms = {
    'ubuntu' => {
      'versions' => ['12.04'],
      'user' => 'bind',
      'group' => 'bind',
      'config_dir' => '/etc/bind',
      'zones_dir' => '/etc/bind/zones'
     }
  }
  platforms.each do |platform,vals|
    vals['versions'].each do |version|
      context "On #{platform} #{version}" do
        let(:chef_run) do
          ChefSpec::Runner.new(:platform=>platform,:version=>version) do |node|
            node.set[:bind9][:chroot_dir] = '/var/chroot/named'
          end.converge(described_recipe)
        end

        before(:each) do
          File.stub(:readlines).with(anything).and_call_original
          File.stub(:readlines).with('/etc/init.d/bind9').and_return(['/var/run/named'])
          File.stub(:directory?).with(anything).and_call_original
          File.stub(:directory?).with('/var/chroot/named/usr/lib/x86_64-linux-gnu/openssl-1.0.0').and_return(true)
        end

        if platform == 'ubuntu'
          it 'does not run ruby_block copy_openssl_dependencies when /var/chroot/named/usr/lib/x86_64-linux-gnu/openssl-1.0.0 exists' do
            expect(chef_run).to_not run_ruby_block('copy_openssl_dependencies')
          end

          it 'does not run ruby_block copy_openssl_dependencies when /usr/lib/x86_64-linux-gnu/openssl-1.0.0 does not exist' do
            File.stub(:directory?).with('/usr/lib/x86_64-linux-gnu/openssl-1.0.0').and_return(false)
            expect(chef_run).to_not run_ruby_block('copy_openssl_dependencies')
          end

          it 'runs ruby_block copy_openssl_dependencies' do
            File.stub(:directory?).with('/var/chroot/named/usr/lib/x86_64-linux-gnu/openssl-1.0.0').and_return(false)
            expect(chef_run).to run_ruby_block('copy_openssl_dependencies')
          end

          it 'runs ruby_block modify_init_script' do
            expect(chef_run).to run_ruby_block('modify_init_script')
          end

          it 'does not run ruby_block modify_init_script' do
            File.stub(:readlines).with(anything).and_call_original
            File.stub(:readlines).with('/etc/init.d/bind9').and_return([''])
            expect(chef_run).to_not run_ruby_block('modify_init_script')
          end

          it 'enables apparmor service' do
            expect(chef_run).to enable_service('apparmor')
          end

          it 'creates /etc/apparmor.d/local/usr.sbin.named' do
            File.stub(:exists?).with(anything).and_call_original
            File.stub(:exists?).with('/etc/apparmor.d/local/usr.sbin.named').and_return(true)
            expect(chef_run).to create_template('/etc/apparmor.d/local/usr.sbin.named').with(
              user: 'root',
              group: 'root',
              mode: '0644'
            )
          end

          it 'does not create /etc/apparmor.d/local/usr.sbin.named' do
            File.stub(:exists?).with(anything).and_call_original
            File.stub(:exists?).with('/etc/apparmor.d/local/usr.sbin.named').and_return(false)
            expect(chef_run).to_not create_template('/etc/apparmor.d/local/usr.sbin.named')
          end

          it '/etc/apparmor.d/local/usr.sbin.named restarts apparmor service' do
            expect(chef_run.template('/etc/apparmor.d/local/usr.sbin.named')).to notify('service[apparmor]').immediately
           end
         end

        it 'creates directory /var/chroot/named/var/run/named' do
          expect(chef_run).to create_directory('/var/chroot/named/var/run/named').with(
            user: vals['user'],
            group: vals['group'],
            mode: 0744,
            recursive: true
          )
        end

        it "creates directory /var/chroot/named#{vals['config_dir']}" do
          expect(chef_run).to create_directory("/var/chroot/named#{vals['config_dir']}").with(
            user: 'bind',
            group: 'bind',
            mode: 0744,
            recursive: true
          )
        end

        it 'runs ruby_block move_config_to_chroot' do
          File.stub(:symlink?).with(anything).and_call_original
          File.stub(:symlink?).with(vals['config_dir']).and_return(false)
          expect(chef_run).to run_ruby_block('move_config_to_chroot')
        end

        it 'does not run ruby_block move_config_to_chroot' do
          File.stub(:symlink?).with(anything).and_call_original
          File.stub(:symlink?).with(vals['config_dir']).and_return(true)
          expect(chef_run).to_not run_ruby_block('move_config_to_chroot')
        end

        it 'links bind config from chroot' do
          expect(chef_run).to create_link(vals['config_dir']).with(
            to: "/var/chroot/named#{vals['config_dir']}"
          )
        end

        it 'does not link bind zones from chroot' do
          expect(chef_run).to_not create_link(vals['zones_dir']).with(
          to: "/var/chroot/named#{vals['zones_dir']}"
          )
        end

        it 'creates directory /var/chroot/named/dev' do
          expect(chef_run).to create_directory('/var/chroot/named/dev').with(
            user: vals['user'],
            group: vals['group'],
            mode: 0744,
            recursive: true
          )
        end

        it 'creates special device files' do
          expect(chef_run).to run_execute('create_special_device_files')
        end

        it 'does not create special device files' do
          File.stub(:exists?).with(anything).and_call_original
          File.stub(:exists?).with('/var/chroot/named/dev/null').and_return(true)
          expect(chef_run).to_not run_execute('create_special_device_files')
        end

      end
    end
  end
end

