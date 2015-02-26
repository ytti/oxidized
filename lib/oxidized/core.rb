module Oxidized
  require 'oxidized/log'
  require 'oxidized/string'
  require 'oxidized/config'
  require 'oxidized/config/vars'
  require 'oxidized/worker'
  require 'oxidized/nodes'
  require 'oxidized/manager'
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
      trap 'HUP' { nodes.load }
      if CFG.rest?
        begin
          require 'oxidized/web'
        rescue LoadError
          raise OxidizedError, 'oxidized-web not found: sudo gem install oxidized-web - or disable web support by setting "rest: false" in your configuration'
        end
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
