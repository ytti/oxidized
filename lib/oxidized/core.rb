module Oxidized
  class << self
    def new(*args)
      Core.new args
    end
  end

  class Core
    include SemanticLogger::Loggable

    class NoNodesFound < OxidizedError; end

    MIN_WEB_VERSION = '0.17.0'.freeze

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

      # Load extensions, currently only oxidized-web
      # We have different namespaces for oxidized-web, which needs to be
      # adressed if we need a generic way to load extensions:
      # - gem: oxidized-web
      # - module: Oxidized::API
      # - path: oxidized/web
      # - entrypoint: Oxidized::API::Web.new(nodes, configuration)

      # Initialize oxidized-web if requested
      if Oxidized.config.has_key? 'rest'
        logger.warn(
          'configuration: "rest" is deprecated. Migrate to ' \
          '"extensions.oxidized-web" and remove "rest" from the configuration'
        )
        configuration = Oxidized.config.rest
      elsif Oxidized.config.extensions &&
            Oxidized.config.extensions['oxidized-web']&.load?
        # This comment stops rubocop complaining about Style/IfUnlessModifier
        configuration = Oxidized.config.extensions['oxidized-web']
      end

      if configuration
        begin
          require 'oxidized/web'
        rescue LoadError
          raise OxidizedError,
                'oxidized-web not found: install it or disable it by ' \
                'removing "rest" and "extensions.oxidized-web" from your ' \
                'configuration'
        end
        @rest = API::Web.new nodes, configuration
        check_web_version
        @rest.run
      end
      run
    end

    private

    # WEB_VERSION is defined by oxidized/web/webapp, loaded by API::Web.new.
    # Extracted from check_web_version so that core_spec can stub it in tests.
    def web_version
      API::WEB_VERSION if API.const_defined?(:WEB_VERSION)
    end

    def check_web_version
      version = web_version
      return if version.nil? || Gem::Version.new(version) >= Gem::Version.new(MIN_WEB_VERSION)

      logger.warn(
        "oxidized-web #{version} is older than #{MIN_WEB_VERSION}: " \
        'the display of node versions and diffs fails, and puma may ' \
        'override the signal handlers. Please update oxidized-web'
      )
    end

    def reload
      logger.info("Reloading node list")
      @worker.reload
      @need_reload = false
    end

    def run
      logger.debug "Starting the worker..."
      loop do
        reload if @need_reload
        @worker.work
        sleep Config::SLEEP
      end
    end
  end
end
