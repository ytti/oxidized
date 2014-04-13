module Oxidized
 require 'oxidized/node'
 require 'ipaddr'
 class Oxidized::NotSupported < StandardError; end
 class Oxidized::NodeNotFound < StandardError; end
  class Nodes < Array
    attr_accessor :source
    alias :put :unshift
    def load node_want=nil
      with_lock do
        new = []
        node_want_ip = (IPaddr.new(node_want) rescue nil) if node_want
        @source = CFG.source[:default]
        Oxidized.mgr.add_source @source
        Oxidized.mgr.source[@source].new.load.each do |node|

          # we want to load specific node(s), not all of them
          if node_want
            if node_want_ip
              next unless node_want_ip == node[:ip]
            else
              next unless node[:name].match node_want
            end
          end

          begin
            _node = Node.new node
            new.push _node
          rescue ModelNotFound => err
            Log.error "node %s raised %s with message '%s'" % [node, err.class, err.message]
          rescue Resolv::ResolvError => err
            Log.error "node %s is not resolvable, raised %s with message '%s'" % [node, err.class, err.message]
          end
        end
        replace new
      end
    end

    def list
      with_lock do
        map { |e| e.serialize }
      end
    end

    def show node
      with_lock do
        i = find_node_index node
        self[i].serialize
      end
    end

    def fetch node, group
      with_lock do
        i = find_node_index node
        output = self[i].output.new
        raise Oxidized::NotSupported unless output.respond_to? :fetch
        output.fetch node, group
      end
    end

    # @param node [String] name of the node moved into the head of array
    def next node, opt={}
      with_lock do
        n = del node
        if n
          n.user = opt['user']
          n.msg  = opt['msg']
          n.from = opt['from']
          # set last job to nil so that the node is picked for immediate update
          n.last = nil
          put n
        end
      end
    end
    alias :top :next
    # @return [String] node from the head of the array
    def get
      with_lock do
        (self << shift).last
      end
    end

    private

    def initialize opts={}
      super()
      node = opts.delete :node
      @mutex= Mutex.new  # we compete for the nodes with webapi thread
      load node
    end

    def with_lock &block
      @mutex.synchronize(&block)
    end

    def find_index node
      index { |e| e.name == node }
    end

    def find_node_index node
      find_index node or raise Oxidized::NodeNotFound, "unable to find '#{node}'"
    end

    def del node
      delete_at find_node_index(node)
    end
  end
end
