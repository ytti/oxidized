require_relative '../spec_helper'
require 'oxidized/model/model'

# rubocop:disable Style/FormatStringToken

class TestModel < Oxidized::Model
  using Refinements

  comment '! '

  metadata :top do
    comment "Fetched by Oxidized with model #{self.class.name} from host #{@node.name} [#{@node.ip}]\n"
  end

  metadata :bottom, "! End of configuration for host %{name}\n"

  expect(/^--More--$/) do |data, re|
    send ' '
    data.sub re, ''
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'conditional command', if: lambda {
    # Use lambda when multiple lines are needed
    vars("condition")
  } do |cfg|
    @run_second_command = "go"
    comment cfg
  end

  cmd 'second command', if: -> { @run_second_command == "go" } do |cfg|
    comment cfg
  end

  pre do
    "Prepended output after cmd blocks have been run\n"
  end

  post do
    "Appended output after cmd blocks have been run\n"
  end

  cfg :ssh, :telnet do
    pre_logout 'logout'
  end
end

class TestModelNoMetadata < Oxidized::Model
  using Refinements
  cmd 'show configuration'
  comment '// '
end

describe 'Oxidized::Model' do
  before do
    Oxidized.asetus = Asetus.new
  end
  describe 'class methods' do
    describe '.metadata' do
      it 'stores metadata at top position with a block' do
        metadata = TestModel.instance_variable_get(:@metadata)
        _(metadata[:top]).must_be_kind_of Proc
      end

      it 'stores metadata at bottom position with a string' do
        metadata = TestModel.instance_variable_get(:@metadata)
        _(metadata[:bottom]).must_equal "! End of configuration for host %{name}\n"
      end

      it 'does not store metadata when not defined' do
        metadata = TestModelNoMetadata.instance_variable_get(:@metadata)
        _(metadata[:top]).must_be_nil
        _(metadata[:bottom]).must_be_nil
      end
    end

    describe '.cmd/.cmds' do
      before do
        @test_model = Class.new(Oxidized::Model)
        @block_upcase = proc { |data| data.upcase }
        @block_downcase = proc { |data| data.downcase }
      end
      describe 'with :all symbol' do
        it 'adds a block' do
          @test_model.cmd(:all, &@block_upcase)
          _(@test_model.cmds[:all]).must_include @block_upcase
        end
        it 'can add multiple blocks' do
          @test_model.cmd(:all, &@block_upcase)
          @test_model.cmd(:all, &@block_downcase)
          cmds = @test_model.cmds
          _(cmds[:all].size).must_equal 2
          _(cmds[:all]).must_include @block_upcase
          _(cmds[:all]).must_include @block_downcase
        end
      end

      describe 'with string' do
        it 'adds a block' do
          @test_model.cmd("show version", &@block_upcase)
          cmds = @test_model.cmds

          _(cmds[:cmd]).wont_be_empty
          _(cmds[:cmd].first).must_equal(
            { cmd: "show version", args: {}, block: @block_upcase }
          )
        end
        it 'adds a command without a block' do
          @test_model.cmd("show version")
          cmds = @test_model.cmds

          _(cmds[:cmd]).wont_be_empty
          _(cmds[:cmd].first[:cmd]).must_equal "show version"
          _(cmds[:cmd].first[:block]).must_be_nil
        end
        it 'adds a command multiple times' do
          @test_model.cmd("show version", &@block_upcase)
          @test_model.cmd("show version", &@block_downcase)
          @test_model.cmd("show version", prepend: true)
          cmds = @test_model.cmds

          _(cmds[:cmd].size).must_equal 3
          _(cmds[:cmd][0][:cmd]).must_equal "show version"
          _(cmds[:cmd][0][:block]).must_be_nil
          _(cmds[:cmd][0][:args]).must_equal({ prepend: true })
          _(cmds[:cmd][1][:cmd]).must_equal "show version"
          _(cmds[:cmd][1][:block]).must_equal @block_upcase
          _(cmds[:cmd][2][:block]).must_equal @block_downcase
        end
        it 'can prepend a command' do
          @test_model.cmd("show version")
          @test_model.cmd("prepended command", prepend: true, &@block_upcase)
          cmds = @test_model.cmds
          _(cmds[:cmd].size).must_equal 2
          _(cmds[:cmd][0][:cmd]).must_equal "prepended command"
          _(cmds[:cmd][0][:args]).must_equal({ prepend: true })
          _(cmds[:cmd][0][:block]).must_equal @block_upcase
          _(cmds[:cmd][1][:cmd]).must_equal "show version"
        end
        it 'can clear a command' do
          @test_model.cmd("command", &@block_upcase)
          @test_model.cmd("other")
          @test_model.cmd("command", clear: true, &@block_downcase)
          cmds = @test_model.cmds
          _(cmds[:cmd].size).must_equal 2
          _(cmds[:cmd][0][:cmd]).must_equal "other"
          _(cmds[:cmd][1][:cmd]).must_equal "command"
          _(cmds[:cmd][1][:args]).must_equal({ clear: true })
          _(cmds[:cmd][1][:block]).must_equal @block_downcase
        end
      end
    end

    describe '.cfg/.cfgs' do
      it 'stores and returns input configs' do
        cfgs = TestModel.cfgs
        _(cfgs.size).must_equal 2
        _(cfgs).must_include "ssh"
        _(cfgs).must_include "telnet"
        _(cfgs["ssh"].first).must_be_kind_of Proc
      end
    end
    describe '.expect/.expects' do
      it 'stores and returns expectations' do
        expects = TestModel.expects
        _(expects.size).must_equal 1
        _(expects.first[0]).must_equal(/^--More--$/)
        _(expects.first[1]).must_be_kind_of Proc
      end
    end

    describe '.procs' do
      it 'stores and returns pre/post procs' do
        procs = TestModel.procs
        _(procs.size).must_equal 2
        _(procs).must_include :pre
        _(procs).must_include :post
        _(procs[:pre].first).must_be_kind_of Proc
        _(procs[:post].first).must_be_kind_of Proc
      end
    end
  end

  describe 'object methods' do
    before do
      @mock_node = mock('Oxidized::Node')
      @mock_node.stubs(:name).returns('router1')
      @mock_node.stubs(:ip).returns('192.168.1.1')
      @mock_node.stubs(:group).returns('gr1')

      @mock_input = mock('Oxidized::Input')
      @mock_input.stubs(:output).returns(nil)
      @mock_input.stubs(:cmd).with('show version').returns("Version 1.0\n")
      @mock_input.stubs(:cmd).with('show configuration').returns("Sample config\n")

      @model = TestModel.new
      @model.input = @mock_input
      @model.node = @mock_node

      # Default: vars are not present
      @model.stubs(:vars).returns(nil)
    end
    describe '#metadata' do
      it 'returns string value for bottom position' do
        result = @model.metadata(:bottom)
        _(result).must_equal "! End of configuration for host router1\n"
      end

      it 'evaluates proc for top position with instance context' do
        result = @model.metadata(:top)
        _(result).must_equal "! Fetched by Oxidized with model TestModel from host router1 [192.168.1.1]\n"
      end
    end

    describe '#get' do
      it 'includes bottom metadata when vars metadata is true' do
        @model.stubs(:vars).with('metadata').returns(true)

        result = @model.get.to_cfg
        _(result).must_equal(
          "! Fetched by Oxidized with model TestModel from host router1 [192.168.1.1]\n" \
          "Prepended output after cmd blocks have been run\n" \
          "! Version 1.0\n" \
          "Appended output after cmd blocks have been run\n" \
          "! End of configuration for host router1\n"
        )
      end

      it 'does not include metadata when vars metadata is not true' do
        result = @model.get.to_cfg
        _(result).wont_include '! Fetched by Oxidized'
        _(result).wont_include '! End of configuration'
      end

      it 'falls back to vars when neither top nor bottom metadata is defined' do
        model = TestModelNoMetadata.new
        model.input = @mock_input
        model.node = @mock_node

        model.stubs(:vars).returns(nil)
        model.stubs(:vars).with('metadata').returns(true)
        model.stubs(:vars).with('metadata_top').returns("%{comment}Top from vars model %{model}\n")
        model.stubs(:vars).with('metadata_bottom').returns("%{comment}Bottom from vars\n")

        result = model.get.to_cfg
        _(result).must_equal(
          "// Top from vars model TestModelNoMetadata\n" \
          "Sample config\n" \
          "// Bottom from vars\n"
        )
      end

      it 'falls back to vars(top) when neither top nor bottom metadata is defined' do
        model = TestModelNoMetadata.new
        model.input = @mock_input
        model.node = @mock_node

        model.stubs(:vars).returns(nil)
        model.stubs(:vars).with('metadata').returns(true)
        model.stubs(:vars).with('metadata_top').returns("%{comment}Top from vars model %{model}\n")

        result = model.get.to_cfg
        _(result).must_equal(
          "// Top from vars model TestModelNoMetadata\n" \
          "Sample config\n"
        )
      end

      it 'Falls back to METADATA_DEFAULT in metadata_top when nothing else is defined' do
        model = TestModelNoMetadata.new
        model.input = @mock_input
        model.node = @mock_node

        model.stubs(:vars).returns(nil)
        model.stubs(:vars).with('metadata').returns(true)

        result = model.get.to_cfg
        _(result).must_equal(
          "// Fetched by Oxidized with model TestModelNoMetadata from host router1 [192.168.1.1]\n" \
          "Sample config\n"
        )
      end

      it 'executes conditional commands when the condition is met' do
        @model.stubs(:vars).with('condition').returns(true)
        @mock_input.expects(:cmd).with('conditional command').returns("conditional command result\n")
        @mock_input.expects(:cmd).with('second command').returns("second command result\n")

        result = @model.get.to_cfg
        _(result).must_equal(
          "Prepended output after cmd blocks have been run\n" \
          "! Version 1.0\n" \
          "! conditional command result\n" \
          "! second command result\n" \
          "Appended output after cmd blocks have been run\n"
        )
      end
    end

    describe '#interpolate_string' do
      before do
        fixed_time = Time.new(2025, 11, 3, 14, 5, 9)
        Time.stubs(:now).returns(fixed_time)
      end
      {
        "%{model}"   => "TestModel",
        "%{name}"    => "router1",
        "%{ip}"      => "192.168.1.1",
        "%{group}"   => "gr1",
        "%{comment}" => "! ",
        "%{year}"    => "2025",
        "%{month}"   => "11",
        "%{day}"     => "03",
        "%{hour}"    => "14",
        "%{minute}"  => "05",
        "%{second}"  => "09"
      }.each do |template, expected|
        it "interpolates #{template}" do
          _(@model.interpolate_string(template)).must_equal expected
        end
      end
    end
  end
end
# rubocop:enable Style/FormatStringToken
