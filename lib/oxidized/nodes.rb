module Oxidized
  require 'oxidized/node'
 class Oxidized::NotSupported < StandardError; end
 class Oxidized::NodeNotFound < StandardError; end
  class Nodes < Array
    attr_accessor :source
    alias :put :unshift
    def initialize *args
      super
      @mutex= Mutex.new  # we compete for the nodes with webapi thread
      load if args.empty?
    end
    def load
      lock
      new = []
      @source = CFG.source[:default]
      Oxidized.mgr.source = @source
      Oxidized.mgr.source[@source].new.load.each do |node|
        new.push Node.new node
      end
      unlock(replace new)
    end
    def list
      lock
      unlock(map { |e| e.serialize })
    end
    def show node
      lock
      i = find_node_index node
      unlock(self[i].serialize)
    end
    def fetch node, group
      lock
      i = find_node_index node
      output = self[i].output.new
      unlock
      raise Oxidized::NotSupported unless output.respond_to? :fetch
      output.fetch node, group
    end
    def del node
      lock
      unlock(delete_at find_node_index(node))
    end
    # @param node [String] name of the node moved into the head of array
    def next node, opt={}
      lock
      n = del node
      if n
        n.user = opt['user']
        n.msg  = opt['msg']
        n.from = opt['from']
        put n
      end
      unlock
    end
    alias :top :next
    # @return [String] node from the head of the array
    def get
      lock
      unlock((self << shift).last)
    end

    private

    def lock
      @mutex.lock unless @mutex.owned?
    end

    def unlock arg=nil
      @mutex.unlock if @mutex.owned?
      arg
    end

    def find_index node
      index { |e| e.name == node }
    end

    def find_node_index node
      find_index node or raise Oxidized::NodeNotFound, "unable to find '#{node}'"
    end
  end
end
