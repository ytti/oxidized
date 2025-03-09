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

      # Load extentions, currently only oxidized-web
      # We have different namespaces for oxidized-web, which needs to be
      # adressed if we need a generic way to load extentions:
      # - gem: oxidized-web
      # - module: Oxidized::API
      # - path: oxidized/web
      # - entrypoint: Oxidized::API::Web.new(nodes, configuration)

      # Warn about deprecated configuration
      if Oxidized.config.rest? &&
         Oxidized.config.extentions.has_key?('oxidized-web')
        Oxidized.logger.warn(
          'configuration: both "rest" and "extentions.oxidized-web" are ' \
          'defined. "extentions.oxidized-web" will be used, remove "rest"'
        )
      end

      # Initialize oxidized-web if requested
      if Oxidized.config.extentions.has_key?('oxidized-web')
        if Oxidized.config.extentions['oxidized-web'].load?
          # This comment stops rubocop complaining about Style/IfUnlessModifier
          configuration = Oxidized.config.extentions['oxidized-web']
        end
      elsif Oxidized.config.rest?
        Oxidized.logger.warn(
          'configuration: "rest" is depreacated. Migrate to ' \
          '"extentions.oxidized-web"'
        )
        configuration = Oxidized.config.rest
      end

      if configuration
        begin
          require 'oxidized/web'
        rescue LoadError
          raise OxidizedError,
                'oxidized-web not found: install it or disable it by ' \
                'removing "rest" and "extentions.oxidized-web" from your ' \
                'configuration'
        end
        @rest = API::Web.new nodes, configuration
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
