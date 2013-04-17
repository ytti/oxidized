module Oxidized
  require 'oxidized/node'
  class Nodes < Array
    attr_accessor :source
    alias :del :delete
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
      self
    end
    # @param node [String] name of the node inserted into nodes array
    def put node
      unshift node
    end
    # @param node [String] name of the node moved into the head of array
    def top node
      n = del node
      put n if n
    end
    # @return [String] node from the head of the array
    def get
      (self << shift).last
    end
  end
end
