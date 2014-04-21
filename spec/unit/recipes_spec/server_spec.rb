require 'spec_helper'

ChefSpec::Coverage.start! do
  add_filter '*/bind9-chroot/recipes/chroot.rb'
end

describe 'bind9-chroot::server' do
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
  end

  PLATFORMS.each do |p|
    context "#{p['platform']} #{p['version']}" do
      let(:chef_run) { ChefSpec::Runner.new(:platform=>p['platform'],:version=>p['version']).converge(described_recipe) }
    
      it "installs #{p['package']}" do
        expect(chef_run).to install_package(p['package'])
      end

      it "enables #{p['service']} service" do
        expect(chef_run).to enable_service(p['service'])
      end

      it "creates directory #{p['data_path']} owned by #{p['user']} user" do
        expect(chef_run).to create_directory(p['data_path']).with(
          user: p['user'],
          group: p['user'],
          mode: 0755,
          recursive: true
        )
      end

      it "creates directory #{p['log_dir']} owned by bind user" do
        expect(chef_run).to create_directory(p['log_dir']).with(
          user: p['user'],
          group: p['user'],
          mode: 0755,
          recursive: true
        )
      end

      it "creates directory #{p['zone_path']} owned by bind user" do
        expect(chef_run).to create_directory(p['zone_path']).with(
          user: p['user'],
          group: p['user'],
          mode: 0744,
          recursive: true
        )
      end
   
      context 'chroot_dir exists' do
        let(:chef_run) do
          ChefSpec::Runner.new(:platform=>p['platform'],:version=>p['version']) do |node|
            node.set[:bind9][:chroot_dir] = '/var/run/bind'
          end.converge(described_recipe)
        end
        before(:each) do
          File.stub(:readlines).with(anything).and_call_original
          File.stub(:readlines).with('/etc/init.d/bind9').and_return(['/var/run/named'])
        end
  
        it 'includes bind9-chroot::chroot recipe' do
          expect(chef_run).to include_recipe('bind9-chroot::chroot')
        end

        it "creates directory /var/run/bind#{p['data_path']} owned by #{p['user']}" do
          expect(chef_run).to create_directory("/var/run/bind#{p['data_path']}").with(
            user: p['user'],
            group: p['user'],
            mode: 0755,
            recursive: true
          )
        end

        it "creates directory /var/run/bind#{p['log_dir']} owned by #{p['user']}" do
          expect(chef_run).to create_directory("/var/run/bind#{p['log_dir']}").with(
            user: p['user'],
            group: p['user'],
            mode: 0755,
            recursive: true
          )
        end

        it "creates directory /var/run/bind#{p['zone_path']} owned by #{p['user']}" do
          expect(chef_run).to create_directory("/var/run/bind#{p['zone_path']}").with(
            user: p['user'],
            group: p['user'],
            mode: 0744,
            recursive: true
          )
        end

      end
    
      it 'does not include bind9-chroot::chroot recipe' do
        expect(chef_run).to_not include_recipe('resolvconf')
      end

      it 'does not include resolvconf recipe' do
        expect(chef_run).to_not include_recipe('resolvconf')
      end

      it 'includes resolvconf recipe' do
        chef_run.node.set[:bind9][:resolvconf] = true
        chef_run.converge(described_recipe)
        expect(chef_run).to include_recipe('resolvconf')
      end

      it "creates template #{p['config_path']}/#{p['options_file']}" do
        expect(chef_run).to create_template("#{p['config_path']}/#{p['options_file']}").with(
          user: p['user'],
          group: p['user'],
          mode: 0644,
        )
      end

      it "creates template #{p['config_path']}/#{p['config_file']}" do
        expect(chef_run).to create_template("#{p['config_path']}/#{p['config_file']}").with(
          user: p['user'],
          group: p['user'],
          mode: 0644,
        )
      end

      it "#{p['config_path']}/#{p['config_file']} notifies bind9 to restart" do
        expect(chef_run.template("#{p['config_path']}/#{p['config_file']}")).to notify('service[bind9]').to(:restart)
      end

      it "creates #{p['config_path']}/#{p['local_file']}" do
        expect(chef_run).to create_template("#{p['config_path']}/#{p['local_file']}").with(
          user: p['user'],
          group: p['user'],
          mode: 0644,
          variables: { :zonefiles => zones }
        )
      end

      it "#{p['config_path']}/#{p['local_file']} notifies bind9 to restart" do
        expect(chef_run.template("#{p['config_path']}/#{p['local_file']}")).to notify('service[bind9]').to(:restart)
      end

      case p['platform']
      when 'ubuntu'
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
      end

      it "does not create #{p['zone_path']}/example.com" do
        expect(chef_run).to_not create_template("#{p['zone_path']}/example.com").with(
          source: '/etc/bind/zones/example.com.erb',
          local: true,
          user: p['user'],
          group: p['user'],
          mode: 0644,
          variables: { :serial => '00000' }
        )
      end

      it "creates #{p['zone_path']}/example.com.erb" do
        expect(chef_run).to create_template("#{p['zone_path']}/example.com.erb").with(
          source: 'zonefile.erb',
          user: p['user'],
          group: p['user'],
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

      it "notifies #{p['zone_path']}/example.com immediately" do
        expect(chef_run.template("#{p['zone_path']}/example.com.erb")).to notify("template[#{p['zone_path']}/example.com]").to(:create).immediately
      end

      it "starts #{p['service']} service" do
        expect(chef_run).to start_service('bind9')
      end

    end
  end
end
