require 'spec_helper'
require 'oxid
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
