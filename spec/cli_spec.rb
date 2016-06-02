require 'spec_helper'
require 'oxidized/cli'

describe Oxidized::CLI do
  before do
    @original = ARGV
    @asetus = Asetus.new
  end
  after  { ARGV.replace @original }

  %w[-v --version].each do |option|
    describe option do
      before { ARGV.replace([option]) }

      it 'prints the version and exits' do
        Asetus.expects(:new).returns(@asetus)
        Kernel.expects(:exit)

        assert_output("#{Oxidized::VERSION}\n") { Oxidized::CLI.new }
      end
    end
  end
end
