require_relative '../spec_helper'
require 'oxidized/output/file'

describe 'Oxidized::Output::File' do
  describe '#setup' do
    it 'raises Oxidized::NoConfig when no config is provided' do
      Asetus.any_instance.expects(:load)
      Asetus.any_instance.expects(:create).returns(false)
      # we do not want to create the config for real
      Asetus.any_instance.expects(:save)

      # Set :home_dir to make sure the OXIDIZED_HOME environment variable is not used
      Oxidized::Config.load({ home_dir: '/cfg_path/' })

      Oxidized.config.output.file = ''
      oxidized_file = Oxidized::Output::File.new

      err = _(-> { oxidized_file.setup }).must_raise Oxidized::NoConfig
      _(err.message).must_match(/^no output file config, edit \/cfg_path\/config$/)
    end
  end
end
