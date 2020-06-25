module Oxidized
  require 'net/telnet'
  require 'oxidized/input/cli'
  class Telnet < Input
    RescueFail = {}.freeze
    include Input::CLI
    attr_reader :telnet

    def connect(node)
      @node    = node
      @timeout = Oxidized.config.timeout
      @node.model.cfg['telnet'].each { |cb| instance_exec(&cb) }
      @log = File.open(Oxidized::Config::Log + "/#{@node.ip}-telnet", 'w') if Oxidized.config.input.debug?
      port = vars(:telnet_port) || 23

      telnet_opts = {
        'Host'    => @node.ip,
        'Port'    => port.to_i,
        'Timeout' => @timeout,
        'Model'   => @node.model,
        'Log'     => @log
      }

      @telnet = Net::Telnet.new telnet_opts
      begin
        login
      rescue Timeout::Error
        raise PromptUndetect, ['unable to detect prompt:', @node.prompt].join(' ')
      end
      connected?
    end

    def connected?
      @telnet && (not @telnet.sock.closed?)
    end

    def cmd(cmd_str, expect = @node.prompt)
      return send(cmd_str + "\r\n") unless expect

      Oxidized.logger.debug "Telnet: #{cmd_str} @#{@node.name}"
      args = { 'String'  => cmd_str,
               'Match'   => expect,
               'Timeout' => @timeout }
      @telnet.cmd args
    end

    def send(data)
      @telnet.write data
    end

    def output
      @telnet.output
    end

    private

    def expect(regex)
      @telnet.oxidized_expect expect: regex, timeout: @timeout
    end

    def disconnect
      disconnect_cli
      @telnet.close
    rescue Errno::ECONNRESET
    ensure
      @log.close if Oxidized.config.input.debug?
      (@telnet.close rescue true) unless @telnet.sock.closed?
    end
  end
end

class Net::Telnet
  ## how to do this, without redefining the whole damn thing
  ## FIXME: we also need output (not sure I'm going to support this)
  attr_reader :output
  def oxidized_expect(options)
    model    = @options["Model"]
    @log     = @options["Log"]

    expects  = [options[:expect]].flatten
    time_out = options[:timeout] || @options["Timeout"] || Oxidized.config.timeout?

    Timeout.timeout(time_out) do
      line = ""
      rest = ""
      buf  = ""
      loop do
        c = @sock.readpartial(1024 * 1024)
        @output = c
        c = rest + c

        if Integer(c.rindex(/#{IAC}#{SE}/no) || 0) <
           Integer(c.rindex(/#{IAC}#{SB}/no) || 0)
          buf = preprocess(c[0...c.rindex(/#{IAC}#{SB}/no)])
          rest = c[c.rindex(/#{IAC}#{SB}/no)..-1]
        elsif (pt = c.rindex(/#{IAC}[^#{IAC}#{AO}#{AYT}#{DM}#{IP}#{NOP}]?\z/no) ||
                   c.rindex(/\r\z/no))
          buf = preprocess(c[0...pt])
          rest = c[pt..-1]
        else
          buf = preprocess(c)
          rest = ''
        end
        if Oxidized.config.input.debug?
          @log.print buf
          @log.flush
        end
        line += buf
        line = model.expects line
        match = expects.find { |re| line.match re }
        return match if match
      end
    end
  end
end
