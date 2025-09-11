# frozen_string_literal: true

require_relative '../spec_helper'
require_relative 'atoms'
require 'yaml'

def init_model_helper
  Oxidized.asetus = Asetus.new
  Oxidized.config.timeout = 5
  Oxidized.config.prompt = /^([\w.@-]+[#>]\s?)$/
  Oxidized::Node.any_instance.stubs(:resolve_repo)
  Oxidized::Node.any_instance.stubs(:resolve_output)

  # Speed up the tests, do not sleep in the SSH#expect loop
  Object.any_instance.stubs(:sleep)
end

# save the result of a node.run into @filename
# it is already formated for copy & paste into the YAML simulation file
# @result is formated as it is returned by "status, result = @node.run"
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
  include SemanticLogger::Loggable

  def self.caller_model
    File.basename(caller_locations[1].path).split('_').first
  end

  def self.get_node(model = nil)
    model ||= caller_model
    Oxidized::Node.new(name:  'example.com',
                       input: 'ssh',
                       model: model)
  end

  def self.get_result(test_context = nil, test_or_desc)
    test = test_or_desc
    test = ATOMS::TestOutput.new(caller_model, test_or_desc) if test_or_desc.is_a?(String)
    @node = get_node(test.model)
    mockmodel = MockSsh.new(test.simulation)
    Net::SSH.stubs(:start).returns mockmodel
    status, result = @node.run
    test_context&._(status)&.must_equal :success
    result
  end

  # Takes a yaml file with the data used to simulate the model
  def initialize(model)
    if model['commands'].is_a?(Hash)
      @commands = model['commands'].transform_values(&method(:interpolate_yaml))
    elsif model['commands'].is_a?(Array)
      @commands = []
      model['commands'].each do |c|
        @commands << c.transform_values(&method(:interpolate_yaml))
      end
    else
      raise 'MockSsh#initialize: no commands in the simulation file'
    end

    @init_prompt = interpolate_yaml(model['init_prompt'])
  end

  # interpret escaped characters in the YAML block scalar
  def interpolate_yaml(text)
    "\"#{text}\"".undump
  end

  def exec!(cmd)
    logger.debug "exec! called with cmd #{cmd.dump}"

    # exec commands are send without \n, the keys in @commands have a "\n"
    # appended, so we search for cmd + "\n" in @commands
    cmd += "\n"

    if @commands.is_a?(Array)
      raise 'MockSsh#exec!: no more commands left' if @commands.empty?

      command, response = @commands.shift.first
      raise "MockSsh#exec!: Need #{cmd.dump} but simulation provides #{command.dump}" unless cmd == command
    else
      raise "MockSsh#exec!: #{cmd.dump} not defined" unless @commands.has_key?(cmd)

      response = @commands[cmd]
    end

    logger.debug("exec! #{cmd.dump} returns #{response.dump}")
    response
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
    # When in exec mode, no channel is created, so the loop can exit directly
    return unless @channel
    # When no block is given, Oxidized::SSH is disconnecting
    return unless block_given?

    Kernel.loop do
      @channel.receive
      break unless yield
    end
  end

  def closed?
    false
  end
end

# Simulation of Net::SSH::Connection::Channel
class MockChannel
  include SemanticLogger::Loggable

  attr_accessor :on_data_block

  def initialize(commands)
    @commands = commands
    @queue = String.new
  end

  def commands_left?
    @commands.is_a?(Hash) || (@commands.is_a?(Array) && !@commands.empty?)
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

  def receive
    return if @queue.empty?

    # Send data from @queue but clear it first to prevent new data to be lost
    data = @queue
    @queue = String.new
    @on_data_block.call(nil, data)
  end

  def send_data(cmd)
    logger.debug("send_data called with cmd #{cmd.dump}")

    if @commands.is_a?(Array)
      raise 'MockChannel#send_data: no more commands left' if @commands.empty?

      command, response = @commands.shift.first
      raise "MockChannel#send_data: #{cmd.dump} but simulation provides #{command.dump}" unless cmd == command
    else
      raise "MockChannel#send_data: Command #{cmd.dump} not defined" unless @commands.has_key?(cmd)

      response = @commands[cmd]
    end

    logger.debug("MockChannel#send_data #{cmd.dump} returns #{response.dump}")

    @queue << response
  end

  def process; end
end
