# spec_helper.rb
require 'chefspec'
require 'chefspec/berkshelf'
#require 'fakefs/safe'

ChefSpec::Coverage.start!

UBUNTU_OPTS = {
  platform: 'ubuntu',
  version: '12.04'
}

#RSpec.configure do |config|
#  config.include FakeFS::SpecHelpers, fakefs: true
#end
