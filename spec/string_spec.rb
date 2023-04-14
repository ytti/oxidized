require_relative 'spec_helper'
require 'oxidized/string'

describe Oxidized::String do
  let(:all) { ["1\n2\n3\n"] }

  describe '#init' do
    it 'initializer test' do
      output = Oxidized::String.new("test")
      _(output).must_equal 'test'
      _(output).must_be_instance_of Oxidized::String
    end

    it 'test cut_tail' do
      output = Oxidized::String.new("1\n2\n3\n4\n")
      output = output.cut_tail
      _(output).must_equal "1\n2\n3\n"
      _(output).must_be_instance_of Oxidized::String
    end

    it 'test cut_tail on empty string' do
      output = Oxidized::String.new("")
      output = output.cut_tail
      _(output).must_equal ""
      _(output).must_be_instance_of Oxidized::String
    end

    it 'test cut_tail on default string' do
      output = Oxidized::String.new
      output = output.cut_tail
      _(output).must_equal ""
      _(output).must_be_instance_of Oxidized::String
    end

    it 'test cut_head' do
      output = Oxidized::String.new("1\n2\n3\n4\n")
      output = output.cut_head
      _(output).must_equal "2\n3\n4\n"
      _(output).must_be_instance_of Oxidized::String
    end

    it 'test cut_head on empty string' do
      output = Oxidized::String.new("")
      output = output.cut_head
      _(output).must_equal ""
      _(output).must_be_instance_of Oxidized::String
    end

    it 'test cut_head on default string' do
      output = Oxidized::String.new
      output = output.cut_head
      _(output).must_equal ""
      _(output).must_be_instance_of Oxidized::String
    end

    it 'test cut_both' do
      output = Oxidized::String.new("1\n2\n3\n4\n")
      output = output.cut_both
      _(output).must_equal "2\n3\n"
      _(output).must_be_instance_of Oxidized::String
    end

    it 'test cut_both on default string' do
      output = Oxidized::String.new
      output = output.cut_both
      _(output).must_equal ""
      _(output).must_be_instance_of Oxidized::String
    end

    it 'test cut_both on empty string' do
      output = Oxidized::String.new("")
      output = output.cut_both
      _(output).must_equal ""
      _(output).must_be_instance_of Oxidized::String
    end

    it 'test set_cmd' do
      output = Oxidized::String.new("test")
      output.set_cmd("cmd_string")
      _(output).must_equal "test"
      _(output).must_be_instance_of Oxidized::String
      _(output.cmd).must_equal "cmd_string"
      _(output.name).must_equal "cmd_string"
    end

    it 'test set_cmd with name already set' do
      output = Oxidized::String.new("test")
      output.name = "name_string"
      output.set_cmd("cmd_string")
      _(output).must_equal "test"
      _(output).must_be_instance_of Oxidized::String
      _(output.cmd).must_equal "cmd_string"
      _(output.name).must_equal "name_string"
    end

    it 'test initializer with Oxidized::String as parameter w/o spaces' do
      input = Oxidized::String.new("test")
      input.set_cmd("cmd_string")
      output = Oxidized::String.new(input)
      _(output).must_equal "test"
      _(output).must_be_instance_of Oxidized::String
      _(output.cmd).must_equal "cmd_string"
      _(output.name).must_equal "cmd_string"
    end

    it 'test initializer with Oxidized::String as parameter w/ spaces' do
      input = Oxidized::String.new("test")
      input.set_cmd("cmd string")
      output = Oxidized::String.new(input)
      _(output).must_equal "test"
      _(output).must_be_instance_of Oxidized::String
      _(output.cmd).must_equal "cmd string"
      _(output.name).must_equal "cmd_string"
    end
  end
end
