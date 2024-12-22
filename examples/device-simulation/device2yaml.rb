#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/ssh'
require 'optparse'
require 'etc'
require 'timeout'

# This scripts logs in a network device and outputs a yaml file that can be
# used for model unit tests in spec/model/

# This script is quick & dirty - it grew with the time an could be a project
# for its own. It works, and that should be enough ;-)

################# Methods
# Runs cmd in the ssh session, either im exec mode or with a tty
# saves the output to @output
def ssh_exec(cmd)
  puts "\n### Sending #{cmd}..."
  @output&.puts "  #{cmd}: |-"

  if @exec_mode
    @ssh_output = @ssh.exec! cmd + "\n"
  else
    @ses.send_data cmd + "\n"
    shell_wait
  end
  yaml_output('    ')
end

# Wait for the ssh command to be executed, with an idle timout @idle_timeout
# Pressing CTRL-C exits the script
# Pressing ESC termiates the idle timeout
def shell_wait
  @ssh_output = ''
  # ssh_output gets appended by chanel.on-data (below)
  # We store the current length of @ssh_output in @ssh_output_length
  # if @ssh_output.length is bigger than @ssh_output_length, we got new data
  @ssh_output_length = 0

  # Keep track of time for idle timeout
  start_time = Time.now

  # Loop & wait for @idle_timeout seconds after last output
  # 0.1 means that the loop should run at least once per 0.1 second
  @ssh.loop(0.1) do
    # if @ssh_output is longer than our saved length, we got new output
    if @ssh_output_length < @ssh_output.length
      # reset the timer and save the new output length
      start_time = Time.now
      @ssh_output_length = @ssh_output.length
    end

    # We wait for 0.1 seconds if a key was pressed
    begin
      Timeout.timeout(0.1) do
        # Get input // this is a blocking call
        char = $stdin.getch
        # If ctrl-c is pressed, exit the script
        if char == "\u0003"
          puts '### CTRL-C pressed, exiting'
          cleanup
          exit
        end
        # If escape is pressed, terminate idle timeout
        if char == "\e"
          puts "\n### ESC pressed, skipping idle timeout"
          return false
        else
          # if not, send the char through ssh
          @ses.send_data char
        end
      end
    rescue Timeout::Error
      # No key pressed
    end

    # exit the loop when the @idle_timeout has been reached (false = exit)
    Time.now - start_time < @idle_timeout
  end
end

def yaml_output(prepend = '')
  # Now print the collected output to @output
  firstline = true

  # as we want to prepend 'prepend' to each line, we need each_line and chomp
  # chomp removes the trainling \n
  @ssh_output.each_line(chomp: true) do |line|
    # encode line and remove the first and the trailing double quote
    line = line.dump[1..-2]
    if firstline
      # Make sure the leading space of the first line (if present)
      # is coded with \0x20 or YAML block scalars won't work
      line.sub!(/^\A /, '\x20')
      firstline = false
    end
    # Make sure trailing white spaces are coded with \0x20
    line.gsub!(/ $/, '\x20')
    # prepend white spaces for the yaml block scalar
    line = prepend + line
    @output&.puts line
  end
end

def cleanup
  (@ssh.close rescue true) unless @ssh.closed?
  @output&.close
end

################# Main loop

# Define options
options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: device2yaml.rb [user@]host [options]"

  opts.on('-c', '--cmdset file', 'Mandatory: specify the commands to be run') do |file|
    options[:cmdset] = file
  end
  opts.on('-o', '--output file', 'Specify an output YAML-file') do |file|
    options[:output] = file
  end
  opts.on('-t', '--timeout value', Integer, 'Specify the idle timeout beween commands (default: 5 seconds)') do |timeout|
    options[:timeout] = timeout
  end
  opts.on('-e', '--exec-mode', 'Run ssh in exec mode (without tty)') { @exec_mode = true }
  opts.on '-h', '--help', 'Print this help' do
    puts opts
    exit
  end
end

# Catch and parse the first argument
if ARGV[0] && ARGV[0][0] != '-'
  argument = ARGV.shift
  if argument.include?('@')
    ssh_user, ssh_host = argument.split('@')
  else
    ssh_user = Etc.getlogin
    ssh_host = argument
  end
else
  puts 'Missing a host to connect to...'
  puts
  puts optparse
  exit 1
end

# Parse the options
optparse.parse!

# Get the commands to be run against ssh_host
unless options[:cmdset]
  puts 'Missing a command set, use option -c'
  puts
  puts optparse
  exit 1
end
# make an array of commands to send, ignore empty lines
ssh_commands = File.read(options[:cmdset]).split(/\n+|\r+/)

# Defaut idle timeout: 5 seconds, as tests showed that 2 seconds is too short
@idle_timeout = options[:timeout] || 5

# We will use safe navifation (&.) to call the methods on @output only
# if @output is not nil
@output = options[:output] ? File.open(options[:output], 'w') : nil

@ssh = Net::SSH.start(ssh_host,
                      ssh_user,
                      { timeout:                         10,
                        append_all_supported_algorithms: true })

@ssh_output = ''

unless @exec_mode
  @ses = @ssh.open_channel do |ch|
    ch.on_data do |_ch, data|
      @ssh_output += data
      # Output the data to stdout for interactive control
      # remove ANSI escape codes, as they can produce problems
      # The code will be printed as '\e[123m' in the output
      print data.gsub("\e", '\e')
    end
    ch.request_pty(term: 'vt100') do |_ch, success_pty|
      raise "Can't get PTY" unless success_pty

      ch.send_channel_request 'shell' do |_ch, success_shell|
        raise "Can't get shell" unless success_shell
      end
    end
    ch.on_extended_data do |_ch, _type, data|
      $stderr.print "Error: #{data}\n"
    end
  end
end

# YAML begin of file
@output&.puts '---'

if @exec_mode
  # init prompt does not exist and is empty in exec mode
  @output&.puts 'init_prompt:'
else
  # get motd and first prompt
  @output&.puts 'init_prompt: |-'
  shell_wait
  yaml_output '  '
end

@output&.puts "commands:"

begin
  ssh_commands.each do |cmd|
    ssh_exec cmd
  end
rescue Errno::ECONNRESET, Net::SSH::Disconnect, IOError => e
  puts "### Connection closed with message: #{e.message}"
end

@output&.puts 'oxidized_output: |'
@output&.puts '  !! needs to be written by hand or copy & paste from model output'

cleanup
