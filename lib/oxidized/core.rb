module Oxidized
  require 'oxidized/log'
  require 'oxidized/config/core'
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
      @rest        = API::Web.new nodes, CFG.rest if CFG.rest
      @rest.run
      run
    end

    private

    def run
      while true
        @worker.work
        Config::Sleep
      end
    end
  end
end
