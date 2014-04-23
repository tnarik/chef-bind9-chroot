require 'spec_helper'

describe 'Bind9 Server' do

  it 'is listening on port 53' do
    expect(port(53)).to be_listening
  end

  it 'has bind9 service enabled and started' do
    case RSpec.configuration.os[:family]
    when 'Ubuntu'
      expect(service('bind9')).to be_enabled
      expect(service('bind9')).to be_running
    else
      expect(service('named')).to be_enabled
      expect(service('named')).to be_running
    end
  end
end
