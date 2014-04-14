module Oxidized
  require 'oxidized/log'
  require 'oxidized/config'
  require 'oxidized/worker'
  require 'oxidized/nodes'
  require 'oxidized/manager'
  require 'oxidized/api/web'
  class << self
    def new *args
      Core.new args
    end
  end

  class Core
    def initialize args
      Oxidized.mgr = Manager.new
      nodes        = Nodes.new
      @worker      = Worker.new nodes
      if CFG.rest
        @rest        = API::Web.new nodes, CFG.rest
        @rest.run
      end
      run
    end

    private

    def run
      while true
        @worker.work
        sleep Config::Sleep
      end
    end
  end
end
