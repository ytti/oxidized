require 'spec_helper'
require 'oxidized/cli'

describe Oxidized::CLI do
  before { @original = ARGV }
  after  { ARGV.replace @original }

  %w[-v --version].each do |option|
    describe option do
      before { ARGV.replace([option]) }

      it 'prints the version and exits' do
        Oxidized::Config.expects(:load)
        Oxidized.expects(:setup_logger)
        File.expects(:expand_path)
        Kernel.expects(:exit)

        assert_output("#{Oxidized::VERSION}\n") { Oxidized::CLI.new }
      end
    end
  end
end
