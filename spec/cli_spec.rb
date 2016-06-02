require 'spec_helper'
require 'oxidized/cli'

describe Oxidized::CLI do
  let(:asetus) { mock() }

  after  { ARGV.replace @original }
  before { @original = ARGV }

  %w[-v --version].each do |option|
    describe option do
      before { ARGV.push(option) }

      it 'prints the version and exits' do
        Kernel.expects(:exit)

        proc {
          Oxidized::CLI.new
        }.must_output "#{Oxidized::VERSION}\n"
      end
    end
  end
end
