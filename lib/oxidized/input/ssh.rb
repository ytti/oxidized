require 'timeout'
require_relative 'sshbase'
require_relative 'debugyaml'
require_relative 'debugtext'

module Oxidized
  class SSH < SSHBase
    class NoShell < OxidizedError; end

    RESCUE_FAIL = {
      RuntimeError => :warn
    }.freeze

    def self.rescue_fail
      super.merge(RESCUE_FAIL)
    end

    def connect(node) # rubocop:disable Naming/PredicateMethod
      @node        = node
      @output      = String.new('')
      @pty_options = { term: "vt100" }
      @node.model.cfg['ssh'].each { |cb| instance_exec(&cb) }

      @yaml_debug = DebugYAML.new(Oxidized.config.input.debug, @node, config_name)
      @text_debug = DebugText.new(Oxidized.config.input.debug, @node, config_name)

      logger.debug "Connecting to #{@node.name}"
      @ssh = Net::SSH.start(@node.ip, @node.auth[:username], make_ssh_opts)
      unless @exec
        shell_open @ssh
        begin
          login
        rescue Timeout::Error
          raise PromptUndetect, [@output, 'not matching configured prompt', @node.prompt].join(' ')
        end
      end
      connected?
    end

    def cmd(cmd, expect = node.prompt)
      unless cmd.is_a?(String)
        logger.error "cmd must be a String (#{cmd.class}): #{cmd.inspect} @ #{node.name}"
        raise ArgumentError, "cmd must be a String"
      end
      logger.debug "Sending '#{cmd.dump}' @ #{node.name} with expect: #{expect.inspect}"
      cmd_output = if @exec
                     @yaml_debug&.send_data(cmd)
                     @text_debug&.send_data(cmd)
                     @ssh.exec! cmd
                   else
                     cmd_shell(cmd, expect).gsub("\r\n", "\n")
                   end

      # only logging @exec as cmd_shell is handled in the ssh loop
      @yaml_debug&.receive_data(cmd_output) if @exec
      @text_debug&.receive_data(cmd_output) if @exec

      # Make sure we return a String
      cmd_output.to_s
    end

    def send(data)
      @yaml_debug&.send_data(data)
      @text_debug&.send_data(data)
      @ses.send_data data
    end

    attr_reader :output

    def pty_options(hash)
      @pty_options = @pty_options.merge hash
    end

    private

    # We need a specific disconnect for SSH in shell mode, see issue #3725
    def disconnect
      disconnect_cli
      # if disconnect does not disconnect us, give up after timeout
      Timeout.timeout(@node.timeout) { @ssh.loop }
    rescue Errno::ECONNRESET, Net::SSH::Disconnect, IOError => e
      logger.debug 'The other side closed the connection while ' \
                   "disconnecting, raising #{e.class} with #{e.message}"
    rescue Timeout::Error
      logger.debug "#{@node.name} timed out while disconnecting"
    ensure
      @yaml_debug&.close
      @text_debug&.close
      (@ssh.close rescue true) unless @ssh.closed? # rubocop:disable Style/RedundantParentheses
    end

    def shell_open(ssh)
      @ses = ssh.open_channel do |ch|
        ch.on_data do |_ch, data|
          @yaml_debug&.receive_data(data)
          @text_debug&.receive_data(data)
          @output << data
          @output = @node.model.expects @output
        end
        ch.request_pty(@pty_options) do |_ch, success_pty|
          raise NoShell, "Can't get PTY" unless success_pty

          ch.send_channel_request 'shell' do |_ch, success_shell|
            raise NoShell, "Can't get shell" unless success_shell
          end
        end
      end
    end

    def exec(state = nil)
      return nil if vars(:ssh_no_exec)

      state.nil? ? @exec : (@exec = state)
    end

    def cmd_shell(cmd, expect_re)
      @output = String.new('')

      @yaml_debug&.send_data(cmd + newline)
      @text_debug&.send_data(cmd + newline)
      @ses.send_data cmd + newline
      @ses.process
      expect expect_re if expect_re
      @output
    end

    def expect(*regexps)
      regexps = [regexps].flatten
      logger.debug "Expecting #{regexps.inspect} at #{node.name}"
      Timeout.timeout(@node.timeout) do
        @ssh.loop(0.1) do
          sleep 0.1
          match = regexps.find { |regexp| @output.match regexp }
          return match if match

          true
        end
      end
    end
  end
end
