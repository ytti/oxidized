# rubocop:disable Layout/LineContinuationLeadingSpace, Lint/MissingCopEnableDirective
require 'fileutils'
require 'oxidized/input/debugyaml'
require 'yaml'

describe Oxidized::DebugYAML do
  before do
    @node = mock("Oxidized::Node")
    @node.stubs(:ip).returns('192.0.2.42')
  end

  def interpolate_yaml(text)
    "\"#{text}\"".undump
  end

  it 'does not create a debug file when YAML debug is disabled' do
    Oxidized::DebugYAML.any_instance.expects(:logfile).never

    Oxidized::DebugYAML.new(false,     @node, 'ssh')
    Oxidized::DebugYAML.new('text',    @node, 'ssh')
    Oxidized::DebugYAML.new('library', @node, 'ssh')
    Oxidized::DebugYAML.new(nil,       @node, 'ssh')
  end

  it 'writes lines with expected indentation and flushes' do
    Dir.mktmpdir do |dir|
      logfile = File.join(dir, 'debug.yaml')
      Oxidized::DebugYAML.any_instance.expects(:logfile).returns(logfile)
      yaml = Oxidized::DebugYAML.new('yaml', @node, 'ssh')

      yaml.receive_data(" hello\n world \nprompt ")
      yaml.send_data("show version\n")
      yaml.receive_data("Version 42\nprompt ")
      yaml.send_data("show inventory\n")
      yaml.receive_data("  42 SFPs  \nprompt ")
      yaml.close

      expected =
        "---\n" \
        "init_prompt: |-\n" \
        "      \\x20hello\n" \
        "       world\\x20\n" \
        "      prompt\\x20\n" \
        "commands:\n" \
        "  - \"show version\\n\": |-\n" \
        "      Version 42\n" \
        "      prompt\\x20\n" \
        "  - \"show inventory\\n\": |-\n" \
        "      \\x20 42 SFPs \\x20\n" \
        "      prompt\\x20"

      result = File.read(logfile)
      parsed = YAML.safe_load(result)
      _(result).must_equal(expected)
      _(interpolate_yaml(parsed['init_prompt'])).must_equal " hello\n world \nprompt "
      _(interpolate_yaml(parsed['commands'][0]["show version\n"])).must_equal "Version 42\nprompt "
      _(interpolate_yaml(parsed['commands'][1]["show inventory\n"])).must_equal "  42 SFPs  \nprompt "
    end
  end

  it 'tracks partial line state across calls' do
    Dir.mktmpdir do |dir|
      logfile = File.join(dir, 'debug.yaml')
      Oxidized::DebugYAML.any_instance.expects(:logfile).returns(logfile)
      yaml = Oxidized::DebugYAML.new(true, @node, 'ssh')

      # We can't detect end of line vs. end of output => result: "first\\x20"
      yaml.receive_data('first ')
      yaml.receive_data("line\nsecond line\nprompt")
      yaml.send_data("command")
      yaml.close

      expected =
        "---\n" \
        "init_prompt: |-\n" \
        "      first\\x20line\n" \
        "      second line\n" \
        "      prompt\n" \
        "commands:\n" \
        "  - \"command\": |-\n"

      result = File.read(logfile)
      parsed = YAML.safe_load(result)

      _(result).must_equal(expected)
      _(interpolate_yaml(parsed['init_prompt'])).must_equal "first line\nsecond line\nprompt"
      _(parsed['commands'][0]["command"]).must_equal ""
    end
  end

  it 'saves anything received' do
    Dir.mktmpdir do |dir|
      logfile = File.join(dir, 'debug.yaml')
      Oxidized::DebugYAML.any_instance.expects(:logfile).returns(logfile)
      yaml = Oxidized::DebugYAML.new('YAML', @node, 'ssh')

      yaml.send_data("show version")
      yaml.receive_data("Line 1\nLi")
      yaml.receive_data("n")
      # This will be coded to "e\\x20" as we can't predict if we have a partial
      # ouput or an end of output (prompt with trailing space)
      yaml.receive_data("e ")
      yaml.receive_data("2")
      yaml.receive_data("\nLin")

      expected =
        "---\n" \
        "init_prompt: |-\n" \
        "\n" \
        "commands:\n" \
        "  - \"show version\": |-\n" \
        "      Line 1\n" \
        "      Line\\x202\n" \
        "      Lin"

      result = File.read(logfile)
      parsed = YAML.safe_load(result)

      _(result).must_equal(expected)
      _(interpolate_yaml(parsed['init_prompt'])).must_equal ""
      _(interpolate_yaml(parsed['commands'][0]["show version"])).must_equal "Line 1\nLine 2\nLin"

      yaml.close
    end
  end
end
