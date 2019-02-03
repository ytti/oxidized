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
      Oxidized.Hooks = HookManager.from_config(Oxidized.config)
      nodes = Nodes.new
      raise NoNodesFound, 'source returns no usable nodes' if nodes.size.zero?

      @worker = Worker.new nodes
      trap('HUP') { nodes.load }
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

    def run
      Oxidized.logger.debug "lib/oxidized/core.rb: Starting the worker..."
      @worker.work while sleep Config::Sleep
    end
  end
end
