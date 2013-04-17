module Oxidized
  require 'oxidized/log'
  require 'oxidized/config/core'
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
      worker       = Worker.new nodes
      loop { worker.work; sleep 1 }
    end
  end
end
