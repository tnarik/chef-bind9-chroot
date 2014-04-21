# spec_helper.rb
require 'chefspec'
require 'chefspec/berkshelf'

PLATFORMS = [
  {
    'platform' => 'ubuntu',
    'version' => '12.04',
    'package' => 'bind9',
    'service' => 'bind9',
    'user' => 'bind',
    'data_path' => '/var/cache/bind',
    'log_dir' => '/var/log/bind',
    'zone_path' => '/etc/bind/zones',
    'config_path' => '/etc/bind',
    'options_file' => 'named.conf.options',
    'config_file' => 'named.conf',
    'local_file' => 'named.conf.local'
  },
  {
    'platform' => 'centos',
    'version' => '6.5',
    'package' => 'bind',
    'service' => 'named',
    'user' => 'named',
    'data_path' => '/var/named',
    'log_dir' => '/var/log/named',
    'zone_path' => '/var/named/zones',
    'config_path' => '/etc/named',
    'options_file' => 'named.conf.options',
    'config_file' => 'named.conf',
    'local_file' => 'named.conf.local'
  }
]

RSpec.configure do |config|
  config.color_enabled = true
  config.tty = true
  config.formatter = :documentation
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

#at_exit { ChefSpec::Coverage.report! }
