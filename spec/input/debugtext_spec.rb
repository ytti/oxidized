# require_relative '../spec_helper'
require 'fileutils'
require 'oxidized/input/debugtext'

describe Oxidized::DebugText do
  before do
    @node = mock("Oxidized::Node")
    @node.stubs(:ip).returns('192.0.2.42')
  end

  it 'does not create a debug file when Text debug is not enabled' do
    Oxidized::DebugText.any_instance.expects(:logfile).never

    Oxidized::DebugText.new(false,     @node, 'ssh')
    Oxidized::DebugText.new('yaml',    @node, 'ssh')
    Oxidized::DebugText.new('library', @node, 'ssh')
    Oxidized::DebugText.new(nil,       @node, 'ssh')
  end

  it 'saves anything received' do
    Dir.mktmpdir do |dir|
      logfile = File.join(dir, 'debug.text')
      Oxidized::DebugText.any_instance.expects(:logfile).returns(logfile)
      text = Oxidized::DebugText.new('text', @node, 'ssh')

      text.send_data("show version")
      text.receive_data("Line 1\nLi")
      text.receive_data("n")
      text.receive_data("e ")
      text.receive_data("2")
      text.receive_data("\nLin")

      expected =
        "sent cmd \"show version\"\n" \
        "received \"Line 1\\nLi\"\n" \
        "received \"n\"\n" \
        "received \"e \"\n" \
        "received \"2\"\n" \
        "received \"\\nLin\"\n"

      _(File.read(logfile)).must_equal(expected)

      text.close
    end
  end
end
