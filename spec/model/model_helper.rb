require_relative '../spec_helper'
require 'yaml'

def init_model_helper
  Oxidized.asetus = Asetus.new
  # Set to true in your unit test if you want a lot of logs while debugging
  # You will need to run Oxidized.setup_logger again inside your unit test
  # after setting Oxidized.asetus.cfg.debug to true
  Oxidized.asetus.cfg.debug = false
  Oxidized.config.timeout = 5
  Oxidized.setup_logger

  Oxidized::Node.any_instance.stubs(:resolve_repo)
  Oxidized::Node.any_instance.stubs(:resolve_output)
end

# save the result of a node.run into filename
# it is already formated for copy & paste into the YAML simulation file
# result is dormated as it is returned by "status, result = @node.run"
def result2file(result, filename)
  File.open(filename, 'w') do |file|
    # chomp: true removes the trailing \n after each line
    result.to_cfg.each_line(chomp: true) do |line|
      # encode line and remove first and trailing double quote
      line = line.dump[1..-2]
      # Make sure trailing white spaces are coded with \0x20
      line.gsub!(/ $/, '\x20')
      # prepend white spaces for the yaml block scalar
      line = '  ' + line
      file.write "#{line}\n"
    end
  end
end

# Class to Simulate Net::SSH::Connection::Session
class MockSsh
  attr_reader :oxidized_output

  # Takes a yaml file with the data used to simulate the model
  def initialize(yaml_model)
    @commands = {}
    model = YAML.load_file(yaml_model)
    model['commands'].each do |key, value|
      @commands[key + "\n"] = interpolate_yaml(value)
    end

    @init_prompt = interpolate_yaml(model['init_prompt'])
    @oxidized_output = interpolate_yaml(model['oxidized_output'])
  end

  # We have to interpolate ourselves as yaml block scalars do not interpolate
  # anything
  def interpolate_yaml(text)
    # we just add double quotes and undump the result
    "\"#{text}\"".undump
  end

  def exec!(cmd)
    Oxidized.logger.send(:debug, "exec! called with cmd #{cmd}")

    # exec commands are send without \n, our @commands has \n integrated
    cmd += "\n"

    raise "#{cmd} not defined" unless @commands.has_key?(cmd)

    Oxidized.logger.send(:debug, "exec! returns #{@commands[cmd]}")
    @commands[cmd]
  end

  # Returns Net::SSH::Connection::Channel, which we simulate with MockChannel
  def open_channel
    @channel = MockChannel.new @commands
    yield @channel
    # Now simulate login with the initial @init_prompt
    @channel.on_data_block.call(nil, @init_prompt)
    # Return the simulated Net::SSH::Connection::Channel
    @channel
  end

  def loop(*)
    yield if block_given?
  end

  def closed?
    false
  end
end

# Simulation of Net::SSH::Connection::Channel
class MockChannel
  attr_accessor :on_data_block

  def initialize(commands)
    @commands = commands
  end

  # Saves the block for later use in #send_data
  def on_data(&block)
    @on_data_block = block
  end

  def request_pty(*)
    yield nil, true
  end

  def send_channel_request(*)
    yield nil, true
  end

  def send_data(cmd)
    Oxidized.logger.send(:debug, "send_data called with cmd #{cmd}")
    raise "#{cmd} not defined" unless @commands.has_key?(cmd)

    Oxidized.logger.send(:debug, "send_data returns #{@commands[cmd]}")
    @on_data_block.call(nil, @commands[cmd])
  end

  def process; end
end
