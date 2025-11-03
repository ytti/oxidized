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

  cmd 'show version' do |cfg|
    comment cfg
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
  describe '.metadata class method' do
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
      @model.stubs(:vars).returns('nil')
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
          "! Version 1.0\n" \
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
