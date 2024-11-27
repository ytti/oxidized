require_relative 'spec_helper'
require 'oxidized/config'

describe 'Oxidized::Config' do
  describe '#load' do
    it 'raises Oxidized::NoConfig when no config file is provided' do
      Asetus.any_instance.expects(:load)
      Asetus.any_instance.expects(:create).returns(true)

      err = _(-> { Oxidized::Config.load }).must_raise Oxidized::NoConfig
      # We cannot test if the environment variable OXIDIZED_HOME is properly used.
      # Oxidized::Config uses OXIDIZED_HOME at loading (require 'oxidized/config'),
      # so we have no chance to manipulate it within this test (oxidized/config can
      # have already been required in another test)
      _(err.message).must_match(/^edit .*\/config$/)
    end
  end

  describe '@configfile' do
    it 'returns a path after #load has been called' do
      Asetus.any_instance.expects(:load)
      Asetus.any_instance.expects(:create).returns(false)

      # Set :home_dir to make sure the OXIDIZED_HOME environment variable is not used
      Oxidized::Config.load({ home_dir: '/home/oxidized/.config/oxidized' })
      _(Oxidized::Config.configfile).must_equal('/home/oxidized/.config/oxidized/config')
    end
  end
end
