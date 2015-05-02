require 'spec_helper'

ChefSpec::Coverage.start! do
  add_filter '*/bind9-chroot/recipes/chroot.rb'
end

describe 'bind9-chroot::server' do
  platforms = {
    'ubuntu' => {
      'versions' => ['12.04'],
      'package' => 'bind9',
      'service' => 'bind9',
      'user' => 'bind',
      'group' => 'bind',
      'data_dir' => '/var/cache/bind',
      'log_dir' => '/var/log/named',
      'zones_dir' => '/etc/bind/zones',
      'named_options' => '/etc/bind/named.conf.options',
      'named_conf' => '/etc/bind/named.conf',
      'named_local' => '/etc/bind/named.conf.local'
      
    },
    'centos' => {
      'versions' => ['6.5'],
      'package' => 'bind',
      'service' => 'named',
      'user' => 'named',
      'group' => 'named',
      'data_dir' => '/var/named',
      'log_dir' => '/var/log/named',
      'zones_dir' => '/var/named/zones',
      'named_options' => '/etc/named/named.conf.options',
      'named_conf' => '/etc/named/named.conf',
      'named_local' => '/etc/named/named.conf.local'
      
    }
  }
  let(:zones) { [
    {
      'domain' => 'example.com',
      'type' => 'master',
      'allow_transfer' => [
        '192.168.1.2',
        '192.168.1.3'
      ],
      'also_notify' => [
        '192.168.1.2',
        '192.168.1.3'
      ],
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
            'host' => 'ASPMX.L.GOOGLE.COM',
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
      },
      {
        'domain' => 'example.net',
        'type' => 'slave',
        'masters' => [
          '192.168.1.1'
        ]
      }
    ]
  }  
  let(:zone_file) { '$TTL 300
@ IN SOA ns.example.com. root.example.com. (
                <%= @serial %> ; serial [yyyyMMddNN]
                4H      ; refresh
                30M     ; retry
                1W      ; expiry
                1D      ; minimum
)

                           IN    NS ns.example.com.
                           IN    NS ns1.example.com.
                           IN    NS ns2.example.com.

                           IN    MX 10 ASPMX.L.GOOGLE.COM.

www                        IN     A 127.0.0.1
'
  }

  platforms.each do |platform,vals|
    vals['versions'].each do |version|
      context "On #{platform} #{version}" do
        let(:chef_run) do 
          ChefSpec::Runner.new(:platform=>platform,:version=>version) do |node|
            node.set[:bind9][:zones] = zones
          end.converge(described_recipe)
        end
        let(:node) { chef_run }

        let(:named_conf_local) { "//
// Do any local configuration here
//

// Consider adding the 1918 zones here, if they are not used in your
// organization
//include \"/etc/bind/zones.rfc1918\";

zone \"example.com\" {
  type master;
  file \"#{vals['zones_dir']}/example.com\";
  allow-transfer {
    192.168.1.2;
    192.168.1.3;
  };
  also-notify {
    192.168.1.2;
    192.168.1.3;
  };
};

zone \"example.net\" {
  type slave;
  file \"example.net\";
  masters {
    192.168.1.1;
  };
};"
  }

        before(:each) do
          File.stub(:readlines).with(anything).and_call_original
          File.stub(:readlines).with('/etc/init.d/bind9').and_return(['/var/run/named'])
        end

        it "installs #{vals['package']}" do
          expect(chef_run).to install_package(vals['package'])
        end

        it "enables #{vals['service']} service" do
          expect(chef_run).to enable_service(vals['service'])
        end

        it "creates directory #{vals['data_dir']} owned by #{vals['user']} user" do
          expect(chef_run).to create_directory(vals['data_dir']).with(
            user: vals['user'],
            group: vals['group'],
            mode: 0755,
            recursive: true
          )
        end

        it "creates directory /var/chroot/named#{vals['data_dir']} owned by #{vals['user']} user" do
          chef_run.node.set[:bind9][:chroot_dir] = '/var/chroot/named'
          chef_run.converge(described_recipe)
          expect(chef_run).to create_directory("/var/chroot/named#{vals['data_dir']}").with(
            user: vals['user'],
            group: vals['group'],
            mode: 0755,
            recursive: true
          )
        end

        it "creates directory #{vals['log_dir']} owned by #{vals['user']} user" do
          expect(chef_run).to create_directory(vals['log_dir']).with(
            user: vals['user'],
            group: vals['group'],
            mode: 0755,
            recursive: true
          )
        end

        it "creates directory /var/chroot/named#{vals['log_dir']} owned by #{vals['user']} user" do
          chef_run.node.set[:bind9][:chroot_dir] = '/var/chroot/named'
          chef_run.converge(described_recipe)
          expect(chef_run).to create_directory("/var/chroot/named#{vals['log_dir']}").with(
            user: vals['user'],
            group: vals['group'],
            mode: 0755,
            recursive: true
          )
        end

        it "creates directory #{vals['zones_dir']} owned by #{vals['user']} user" do
          expect(chef_run).to create_directory(vals['zones_dir']).with(
            user: vals['user'],
            group: vals['group'],
            mode: 0744,
            recursive: true
          )
        end

        it "creates directory /var/chroot/named#{vals['zones_dir']} owned by #{vals['user']} user" do
          chef_run.node.set[:bind9][:chroot_dir] = '/var/chroot/named'
          chef_run.converge(described_recipe)
          expect(chef_run).to create_directory("/var/chroot/named#{vals['zones_dir']}").with(
            user: vals['user'],
            group: vals['group'],
            mode: 0744,
            recursive: true
          )
        end

        it 'does not include bind9-chroot::chroot recipe' do
          expect(chef_run).to_not include_recipe('bind9-chroot::chroot')
        end

        it 'includes bind9-chroot::chroot recipe' do
          chef_run.node.set[:bind9][:chroot_dir] = '/var/chroot/named'
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

        it "creates template #{vals['named_options']}" do
          expect(chef_run).to create_template(vals['named_options']).with(
            user: vals['user'],
            group: vals['group'],
            mode: 0644,
          )
        end

        it "creates template #{vals['named_conf']}" do
          expect(chef_run).to create_template(vals['named_conf']).with(
            user: vals['user'],
            group: vals['group'],
            mode: 0644,
          )
        end

        it "#{vals['named_conf']} notifies #{vals['service']} to restart" do
          expect(chef_run.template(vals['named_conf'])).to notify("service[#{vals['service']}]").to(:restart)
        end

        it "creates #{vals['named_local']}" do
          expect(chef_run).to create_template(vals['named_local']).with(
            user: vals['user'],
            group: vals['group'],
            mode: 0644,
            variables: { :zonefiles => Zones }
          )
        end

        it "fills #{vals['named_local']} with correct content" do
          expect(chef_run).to render_file(vals['named_local']).with_content(named_conf_local)
        end

        it "#{vals['named_local']} notifies bind9 to restart" do
          expect(chef_run.template(vals['named_local'])).to notify("service[#{vals['service']}]").to(:restart)
        end

        it 'creates /etc/default/bind9' do
          if chef_run.node[:bind9][:defaults_file]
            expect(chef_run).to create_template('defaults_file').with(
              user: vals['user'],
              group: vals['group'],
              mode: 0644,
            )
          end
        end

        it '/etc/default/bind9 notifies bind9 to restart' do
          expect(chef_run.template('defaults_file')).to notify("service[#{vals['service']}]").to(:restart)
        end

        it 'does not create /etc/default/bind9' do
          if chef_run.node[:bind9][:defaults_file].nil?
            expect(chef_run).to_not create_template('defaults_file').with(
              user: vals['user'],
              group: vals['group'],
              mode: 0644,
            )
          end
        end

        it "recreates directory #{vals['data_dir']} owned by #{vals['user']} user" do
          File.stub(:directory?).with(anything).and_call_original
          File.stub(:directory?).with(vals['zones_dir']).and_return(false)
          File.stub(:symlink?).with(anything).and_call_original
          File.stub(:symlink?).with(vals['zones_dir']).and_return(false)
          expect(chef_run).to create_directory('recreate zones path').with(
            user: vals['user'],
            group: vals['group'],
            mode: 0744,
            recursive: true
          )
        end

        it "does not recreate directory #{vals['data_dir']} owned by #{vals['user']} user" do
          File.stub(:directory?).with(anything).and_call_original
          File.stub(:directory?).with(vals['zones_dir']).and_return(true)
          File.stub(:symlink?).with(anything).and_call_original
          File.stub(:symlink?).with(vals['zones_dir']).and_return(true)
          expect(chef_run).to_not create_directory('recreate zones path').with(
            user: vals['user'],
            group: vals['group'],
            mode: 0744,
            recursive: true
          )
        end

        it "does not create #{vals['zones_dir']}/example.com" do
          expect(chef_run).to_not create_template("#{vals['zones_dir']}/example.com").with(
            source: "#{vals['zones_dir']}/example.com.erb",
            local: true,
            user: vals['user'],
            group: vals['group'],
            mode: 0644,
            variables: { :serial => '00000' }
          )
        end

       it "does not create /var/chroot/named#{vals['zones_dir']}/example.com" do
          chef_run.node.set[:bind9][:chroot_dir] = '/var/chroot/named'
          chef_run.converge(described_recipe)
          expect(chef_run).to_not create_template("/var/chroot/named#{vals['zones_dir']}/example.com").with(
            source: "/var/chroot/named#{vals['zones_dir']}/example.com.erb",
            local: true,
            user: vals['user'],
            group: vals['group'],
            mode: 0644,
            variables: { :serial => '00000' }
          )
        end

        it "creates #{vals['zones_dir']}/example.com.erb" do
          expect(chef_run).to create_template("#{vals['zones_dir']}/example.com.erb").with(
            source: 'zonefile.erb',
            user: vals['user'],
            group: vals['group'],
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
                  'host' => 'ASPMX.L.GOOGLE.COM',
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


        it "fills #{vals['zones_dir']}/example.com.erb with correct content" do
          expect(chef_run).to render_file("#{vals['zones_dir']}/example.com.erb").with_content(zone_file)
        end

        it "notifies #{vals['zones_dir']}/example.com immediately" do
          expect(chef_run.template("#{vals['zones_dir']}/example.com.erb")).to notify("template[#{vals['zones_dir']}/example.com]").to(:create).immediately
        end

        it "does not create #{vals['zones_dir']}/example.net.erb" do
          expect(chef_run).to_not create_template("#{vals['zones_dir']}/example.net.erb")
        end

      end
    end
  end
end
