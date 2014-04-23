# spec_helper.rb
require 'chefspec'
require 'chefspec/berkshelf'

Zones = [
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
    },
    {
      'domain' => 'example.net',
      'type' => 'slave',
      'masters' => [
        '192.168.1.1'
      ]
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
