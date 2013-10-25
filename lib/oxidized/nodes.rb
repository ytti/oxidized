module Oxidized
  require 'oxidized/node'
 class Oxidized::NotSupported < StandardError; end
 class Oxidized::NodeNotFound < StandardError; end
  class Nodes < Array
    attr_accessor :source
    alias :put :unshift
    def initialize *args
      super
      load if args.empty?
    end
    def load
      new = []
      @source = CFG.source[:default]
      Oxidized.mgr.source = @source
      Oxidized.mgr.source[@source].new.load.each do |node|
        new.push Node.new node
      end
      replace new
    end
    def list
      map { |e| e.name }
    end
    def show node
      i = find_node_index node
      self[i].serialize
    end
    def fetch node, group
      i = find_node_index node
      output = self[i].output.new
      raise Oxidized::NotSupported unless output.respond_to? :fetch
      output.fetch node, group
    end
    def del node
      delete_at find_node_index
    end
    # @param node [String] name of the node moved into the head of array
    def next node, opt={}
      require 'pp'
      n = del node
      if n
        n.user = opt['user']
        n.msg  = opt['msg']
        n.from = opt['from']
        put n
      end
    end
    alias :top :next
    # @return [String] node from the head of the array
    def get
      (self << shift).last
    end

    private

    def find_index node
      index { |e| e.name == node }
    end

    def find_node_index node
      find_index node or raise Oxidized::NodeNotFound
    end
  end
end
