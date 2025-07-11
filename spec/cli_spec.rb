require_relative 'spec_helper'
require 'oxidized/cli'

describe Oxidized::CLI do
  before(:each) do
    @original = ARGV
    Oxidized.asetus = Asetus.new
  end

  after(:each) do
    ARGV.replace @original
  end

  %w[-v --version].each do |option|
    describe option do
      before { ARGV.replace([option]) }

      it 'prints the version and exits' do
        Oxidized::Config.expects(:load)
        Oxidized::Logger.expects(:setup)
        File.expects(:expand_path)
        Kernel.expects(:exit)

        assert_output("#{Oxidized::VERSION_FULL}\n") { Oxidized::CLI.new }
      end
    end
  end
end
