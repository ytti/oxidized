require_relative '../spec_helper'
require 'oxidized/source/jsonfile'

# GPGME is an optional runtime dependency that is not installed in the test
# environment; define a minimal stand-in so the gpg branch of #open_file can be
# exercised.
unless defined?(GPGME)
  module GPGME
    # Minimal stand-in for stubbing; the real class is provided by the optional
    # gpgme gem, which is not installed in the test environment.
    class Crypto; end # rubocop:disable Lint/EmptyClass
  end
end

describe Oxidized::Source::JSONFile do
  describe '#setup' do
    before(:each) do
      Asetus.any_instance.expects(:load)
      Asetus.any_instance.expects(:create).returns(false)

      # Set :home_dir to make sure the OXIDIZED_HOME environment variable is not used
      Oxidized::Config.load({ home_dir: '/cfg_path/' })

      @source = Oxidized::Source::JSONFile.new
    end

    it 'raises Oxidized::NoConfig when no config is provided' do
      # we do not want to create the config for real
      Asetus.any_instance.expects(:save)

      Oxidized.config.source.json = ''

      err = _(-> { @source.setup }).must_raise Oxidized::NoConfig
      _(err.message).must_equal 'No source json config, edit /cfg_path/config'
    end

    it 'raises Oxidized::InvalidConfig when name is not provided' do
      Asetus.any_instance.expects(:save).never

      Oxidized.config.source.jsonfile.file = '/cfg_path/router.json'

      err = _(-> { @source.setup }).must_raise Oxidized::InvalidConfig
      _(err.message).must_equal 'map/name is a mandatory source attribute, edit /cfg_path/config'
    end

    it 'passes when name is provided' do
      Asetus.any_instance.expects(:save).never

      Oxidized.config.source.jsonfile.map.name = 'name'

      # returns without an exception
      _(@source.setup).must_be_nil
    end
  end

  describe '#open_file' do
    before(:each) do
      Asetus.any_instance.expects(:load)
      Asetus.any_instance.expects(:create).returns(false)

      Oxidized::Config.load({ home_dir: '/cfg_path/' })

      @source = Oxidized::Source::JSONFile.new
    end

    it 'returns a readable IO for a gpg-encrypted source' do
      # GPG decryption yields a String; open_file wraps it in an IO so every
      # source consumes it the same way as a plain File (issue #3879).
      Oxidized.config.source.jsonfile.file = '/cfg_path/router.json.gpg'
      Oxidized.config.source.jsonfile.gpg  = true

      crypto = mock('crypto')
      crypto.stubs(:decrypt).returns('[{"name": "router1"}]')
      GPGME::Crypto.stubs(:new).returns(crypto)
      File.stubs(:open).returns(StringIO.new(''))

      io = @source.send(:open_file)

      _(io).must_respond_to(:read)
      _(io.read).must_equal('[{"name": "router1"}]')
    end
  end
end
