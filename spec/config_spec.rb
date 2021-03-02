require 'spec_helper'
require 'oxidized/config'

describe Oxidized::Config do
  describe '#load' do
    it 'can load without a config file and provide default values' do
      File.stub(:read, ->(_) { raise Errno::ENOENT }) do
        begin
          Oxidized::Config.load
        rescue Oxidized::NoConfig # rubocop:disable Lint/SuppressedException
        end

        Oxidized.config.username.must_equal 'username'
        Oxidized.config.password.must_equal 'password'
        Oxidized.config.model.must_equal 'junos'
        Oxidized.config.run_command_endpoint.must_equal false
      end
    end
  end
end
