module Oxidized
  require 'oxidized/log'
  require 'oxidized/config/core'
  require 'oxidized/worker'
  require 'oxidized/nodes'
  require 'oxidized/manager'
  require 'oxidized/api/rest'
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
      @rest        = API::Rest.new nodes, CFG.rest if CFG.rest
      run
    end

    private

    def run
      while true
        @worker.work
        @rest ? @rest.work : sleep(Config::Sleep)
      end
    end
  end
end
