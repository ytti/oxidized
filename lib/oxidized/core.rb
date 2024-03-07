module Oxidized
  class << self
    def new(*args)
      Core.new args
    end
  end

  class Core
    class NoNodesFound < OxidizedError; end

    def initialize(_args)
      Oxidized.mgr = Manager.new
      Oxidized.hooks = HookManager.from_config(Oxidized.config)
      nodes = Nodes.new
      raise NoNodesFound, 'source returns no usable nodes' if nodes.empty?

      @worker = Worker.new nodes
      @need_reload = false

      # If we receive a SIGHUP, queue a reload of the state
      reload_proc = proc do
        @need_reload = true
      end
      Signals.register_signal('HUP', reload_proc)

      # Initialize REST API and webUI if requested
      if Oxidized.config.rest?
        begin
          require 'oxidized/web'
        rescue LoadError
          raise OxidizedError, 'oxidized-web not found: sudo gem install oxidized-web - \
          or disable web support by setting "rest: false" in your configuration'
        end
        @rest = API::Web.new nodes, Oxidized.config.rest
        @rest.run
      end
      run
    end

    private

    def reload
      Oxidized.logger.info("Reloading node list and log files")
      @worker.reload
      Oxidized.logger.reopen
      @need_reload = false
    end

    def run
      Oxidized.logger.debug "lib/oxidized/core.rb: Starting the worker..."
      loop do
        reload if @need_reload
        @worker.work
        sleep Config::SLEEP
      end
    end
  end
end
