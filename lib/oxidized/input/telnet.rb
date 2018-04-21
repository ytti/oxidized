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
      port = vars(:telnet_port) || 23

      opt = { 'Host'    => @node.ip,
              'Port'    => port.to_i,
              'Timeout' => @timeout,
              'Model'   => @node.model }
      opt['Output_log'] = Oxidized::Config::Log + "/#{@node.ip}-telnet" if Oxidized.config.input.debug?

      @telnet = Net::Telnet.new opt
      if @node.auth[:username] && !@node.auth[:username].empty?
        expect username
        @telnet.puts @node.auth[:username]
      end
      expect password
      @telnet.puts @node.auth[:password]
      begin
        expect @node.prompt
      rescue Timeout::Error
        raise PromptUndetect, ['unable to detect prompt:', @node.prompt].join(' ')
      end
    end

    def connected?
      @telnet && (not @telnet.sock.closed?)
    end

    def cmd(cmd, expect = @node.prompt)
      Oxidized.logger.debug "Telnet: #{cmd} @#{@node.name}"
      args = { 'String' => cmd }
      if expect
        args['Match'] = expect
        args['Timeout'] = @timeout
      end
      @telnet.cmd args
    end

    def send(data)
      @telnet.write data
    end

    def output
      @telnet.output
    end

    private

    def expect(re)
      @telnet.waitfor 'Match' => re, 'Timeout' => @timeout
    end

    def disconnect
      disconnect_cli
      @telnet.close
    rescue Errno::ECONNRESET
    end
  end
end

class Net::Telnet
  ## FIXME: we just need 'line = model.expects line' to handle pager
  ## how to do this, without redefining the whole damn thing
  ## FIXME: we also need output (not sure I'm going to support this)
  attr_reader :output
  def waitfor(options) # :yield: recvdata
    time_out = @options["Timeout"]
    waittime = @options["Waittime"]
    fail_eof = @options["FailEOF"]
    model    = @options["Model"]

    if options.is_a?(Hash)
      prompt   = if options.has_key?("Match")
                   options["Match"]
                 elsif options.has_key?("Prompt")
                   options["Prompt"]
                 elsif options.has_key?("String")
                   Regexp.new(Regexp.quote(options["String"]))
                 end
      time_out = options["Timeout"]  if options.has_key?("Timeout")
      waittime = options["Waittime"] if options.has_key?("Waittime")
      fail_eof = options["FailEOF"]  if options.has_key?("FailEOF")
    else
      prompt = options
    end

    time_out = nil if time_out == false

    line = ''
    buf = ''
    rest = ''
    until (prompt === line) && (not IO.select([@sock], nil, nil, waittime))
      unless IO.select([@sock], nil, nil, time_out)
        raise TimeoutError, "timed out while waiting for more data"
      end
      begin
        c = @sock.readpartial(1024 * 1024)
        @output = c
        @dumplog.log_dump('<', c) if @options.has_key?("Dump_log")
        if @options["Telnetmode"]
          c = rest + c
          if Integer(c.rindex(/#{IAC}#{SE}/no) || 0) <
             Integer(c.rindex(/#{IAC}#{SB}/no) || 0)
            buf = preprocess(c[0...c.rindex(/#{IAC}#{SB}/no)])
            rest = c[c.rindex(/#{IAC}#{SB}/no)..-1]
          elsif pt = c.rindex(/#{IAC}[^#{IAC}#{AO}#{AYT}#{DM}#{IP}#{NOP}]?\z/no) ||
                     c.rindex(/\r\z/no)
            buf = preprocess(c[0...pt])
            rest = c[pt..-1]
          else
            buf = preprocess(c)
            rest = ''
          end
        else
          # Not Telnetmode.
          #
          # We cannot use preprocess() on this data, because that
          # method makes some Telnetmode-specific assumptions.
          buf = rest + c
          rest = ''
          unless @options["Binmode"]
            if pt = buf.rindex(/\r\z/no)
              buf = buf[0...pt]
              rest = buf[pt..-1]
            end
            buf.gsub!(/#{EOL}/no, "\n")
          end
        end
        @log.print(buf) if @options.has_key?("Output_log")
        line += buf
        line = model.expects line
        line = yield line if block_given?
        yield buf if block_given?
      rescue EOFError # End of file reached
        raise if fail_eof
        if line == ''
          line = nil
          yield nil if block_given?
        end
        break
      end
    end
    line
  end
end
