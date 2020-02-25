module Oxidized
  require "oxidized/input/cli"

  class Exec < Input
    include Input::CLI

    def connect(node)
      @node = node
      @node.model.cfg["exec"].each { |cb| instance_exec(&cb) }
      @log = File.open(Oxidized::Config::Log + "/#{@node.ip}-exec", "w") if Oxidized.config.input.debug?
    end

    def cmd(cmd_str)
      Oxidized.logger.debug "EXEC: #{cmd_str} @ #{@node.name}"
      # I'd really like to do popen3 with separate arguments, but that would
      # require refactoring cmd to take parameters
      %x(#{cmd_str})
    end

    private

    def disconnect
      true
    ensure
      @log.close if Oxidized.config.input.debug?
    end
  end
end
