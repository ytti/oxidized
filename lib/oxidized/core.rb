module Oxidized
  # The Oxidized module serves as the main entry point for the application.
  class << self
    # Creates a new instance of the Core class.
    #
    # @param args [Array] optional arguments passed to the Core initializer
    # @return [Core] a new instance of the Core class
    def new(*args)
      Core.new args
    end
  end

  # The Core class is responsible for managing the core functionalities of the Oxidized application.
  class Core
    require 'oxidized/error/nonodesfound'

    # Initializes the Core instance.
    #
    # This sets up the manager, hooks, nodes, and the worker. It also registers
    # a signal handler for SIGHUP to allow for reloading of nodes.
    #
    # @param _args [Array] optional arguments for initialization
    # @raise [NoNodesFound] if no usable nodes are found
    def initialize(_args)
      Oxidized.mgr = Manager.new
      Oxidized.hooks = HookManager.from_config(Oxidized.config)
      nodes = Nodes.new
      raise NoNodesFound, 'source returns no usable nodes' if nodes.empty?

      @worker = Worker.new nodes
      @need_reload = false

      # @!visibility private
      # If we receive a SIGHUP, queue a reload of the state
      reload_proc = proc do
        @need_reload = true
      end
      Signals.register_signal('HUP', reload_proc)

      # @!visibility private
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

    # Reloads the node list and log files.
    #
    # This method is called when a reload is needed, either due to a SIGHUP
    # or when explicitly invoked.
    #
    # @return [void]
    def reload
      Oxidized.logger.info("Reloading node list and log files")
      @worker.reload
      Oxidized.logger.reopen
      @need_reload = false
    end

    # Starts the main processing loop for the worker.
    #
    # This method continuously checks for reload requests and invokes the
    # worker to perform its tasks at regular intervals defined by the
    # configuration.
    #
    # @return [void]
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
