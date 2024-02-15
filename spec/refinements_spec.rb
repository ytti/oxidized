require_relative 'spec_helper'
require 'refinements'

describe Refinements do
  let(:all) { ["1\n2\n3\n"] }
  using Refinements

  describe '#init' do
    it 'initializer test' do
      output = String.new("test")
      _(output).must_equal 'test'
      _(output).must_be_instance_of String
      _(output.respond_to?(:cut_both)).must_equal true
    end

    it 'test cut_tail' do
      output = String.new("1\n2\n3\n4\n")
      output = output.cut_tail
      _(output).must_equal "1\n2\n3\n"
      _(output).must_be_instance_of String
      _(output.respond_to?(:cut_both)).must_equal true
    end

    it 'test cut_tail on empty string' do
      output = String.new("")
      output = output.cut_tail
      _(output).must_equal ""
      _(output).must_be_instance_of String
      _(output.respond_to?(:cut_both)).must_equal true
    end

    it 'test cut_tail on default string' do
      output = String.new
      output = output.cut_tail
      _(output).must_equal ""
      _(output).must_be_instance_of String
      _(output.respond_to?(:cut_both)).must_equal true
    end

    it 'test cut_head' do
      output = String.new("1\n2\n3\n4\n")
      output = output.cut_head
      _(output).must_equal "2\n3\n4\n"
      _(output).must_be_instance_of String
      _(output.respond_to?(:cut_both)).must_equal true
    end

    it 'test cut_head on empty string' do
      output = String.new("")
      output = output.cut_head
      _(output).must_equal ""
      _(output).must_be_instance_of String
      _(output.respond_to?(:cut_both)).must_equal true
    end

    it 'test cut_head on default string' do
      output = String.new
      output = output.cut_head
      _(output).must_equal ""
      _(output).must_be_instance_of String
      _(output.respond_to?(:cut_both)).must_equal true
    end

    it 'test cut_both' do
      output = String.new("1\n2\n3\n4\n")
      output = output.cut_both
      _(output).must_equal "2\n3\n"
      _(output).must_be_instance_of String
      _(output.respond_to?(:cut_both)).must_equal true
    end

    it 'test cut_both on default string' do
      output = String.new
      output = output.cut_both
      _(output).must_equal ""
      _(output).must_be_instance_of String
      _(output.respond_to?(:cut_both)).must_equal true
    end

    it 'test cut_both on empty string' do
      output = String.new("")
      output = output.cut_both
      _(output).must_equal ""
      _(output).must_be_instance_of String
      _(output.respond_to?(:cut_both)).must_equal true
    end

    it 'test process_cmd' do
      output = String.new("test")
      output.process_cmd("cmd_string")
      _(output).must_equal "test"
      _(output).must_be_instance_of String
      _(output.respond_to?(:cut_both)).must_equal true
      _(output.cmd).must_equal "cmd_string"
      _(output.name).must_equal "cmd_string"
    end

    it 'test process_cmd with name already set' do
      output = String.new("test")
      output.name = "name_string"
      output.process_cmd("cmd_string")
      _(output).must_equal "test"
      _(output).must_be_instance_of String
      _(output.respond_to?(:cut_both)).must_equal true
      _(output.cmd).must_equal "cmd_string"
      _(output.name).must_equal "name_string"
    end
  end

  describe '#init_from_string' do
    it 'initializes instance variables from another string' do
      str1 = "sample string"
      str1.process_cmd("some_command")

      str2 = String.new(str1)
      str2.init_from_string(str1)

      _(str2.instance_variable_get(:@cmd)).must_equal str1.instance_variable_get(:@cmd)
      _(str2.instance_variable_get(:@name)).must_equal str1.instance_variable_get(:@name)
      # :@type is always nil
      _(str2.instance_variable_get(:@type)).must_be_nil
      _(str1.instance_variable_get(:@type)).must_be_nil
    end
  end
end
