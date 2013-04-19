module Oxidized
  require 'oxidized/node'
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
    def find_index node
      index { |e| e.name == node }
    end
    def show node
      i = find_index node
      self[i].serialize if i
    end
    def del node
      i = find_index node
      delete_at i if i
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
  end
end
