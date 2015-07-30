module Oxidized
 require 'ipaddr'
 require 'oxidized/node'
 require 'oxidized/store'
 class Oxidized::NotSupported < OxidizedError; end
 class Oxidized::NodeNotFound < OxidizedError; end
  class Nodes < Array
    attr_accessor :source
    alias :put :unshift
    def load node_want=nil
      with_lock do
        new = []
        @source = CFG.source.default
        Oxidized.mgr.add_source @source
        Oxidized.mgr.source[@source].new.load.each do |node|
          # we want to load specific node(s), not all of them
          next unless node_want? node_want, node
          begin
            _node = Node.new node
            new.push _node
          rescue ModelNotFound => err
            Log.error "node %s raised %s with message '%s'" % [node, err.class, err.message]
          rescue Resolv::ResolvError => err
            Log.error "node %s is not resolvable, raised %s with message '%s'" % [node, err.class, err.message]
          end
        end
        new = save(new)
        size == 0 ? replace(new) : update_nodes(new)
        Log.info "Loaded #{size} nodes"
      end
    end
    
    def save nodes
      new = []
      old_nodes = []
      store = Store.new
      nds = store.get_nodes_stats
      nds.each do |node|
        old_nodes.push node["node"]
      end
      
      #new node first
      nodes.each do |node|
        new.push node unless old_nodes.include? node.name
      end
      #then old in good order
      old_nodes.each do |old_node|
        nodes.each do |node|
          if old_node == node.name
            new.push node
            nodes.delete node
          end
        end     
      end   
      new
    end

    def node_want? node_want, node
      return true unless node_want
      node_want_ip = (IPAddr.new(node_want) rescue false)
      name_is_ip   = (IPAddr.new(node[:name]) rescue false)
      if name_is_ip and node_want_ip == node[:name]
        true
      elsif node[:ip] and node_want_ip == node[:ip]
        true
      elsif node_want.match node[:name]
        true unless name_is_ip
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
      if waiting.find_node_index(node)
        with_lock do
          n = del node
          n.user = opt['user']
          n.msg  = opt['msg']
          n.from = opt['from']
          # set last job to nil so that the node is picked for immediate update
          n.for_update
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

    # @param node node whose index number in Nodes to find
    # @return [Fixnum] index number of node in Nodes
    def find_node_index node
      find_index node or raise Oxidized::NodeNotFound, "unable to find '#{node}'"
    end

    private

    def initialize opts={}
      super()
      node = opts.delete :node
      @mutex= Mutex.new  # we compete for the nodes with webapi thread
      if nodes = opts.delete(:nodes)
        replace nodes
      else
        load node
      end
    end

    def with_lock &block
      @mutex.synchronize(&block)
    end

    def find_index node
      index { |e| e.name == node }
    end

    # @param node node which is removed from nodes list
    # @return [Node] deleted node
    def del node
      delete_at find_node_index(node)
    end

    # @return [Nodes] list of nodes running now
    def running
      Nodes.new :nodes => select { |node| node.running? }
    end

    # @return [Nodes] list of nodes waiting (not running)
    def waiting
      Nodes.new :nodes => select { |node| not node.running? }
    end

    # walks list of new nodes, if old node contains same name, adds last and
    # stats information from old to new.
    #
    # @todo can we trust name to be unique identifier, what about when groups are used?
    # @param [Array] nodes Array of nodes used to replace+update old
    def update_nodes nodes
      old = self.dup
      replace(nodes)
      each do |node|
        begin
          if i = old.find_node_index(node.name)
            node.stats = old[i].stats
            node.last  = old[i].last
          end
        rescue  Oxidized::NodeNotFound
        end
      end
    end
    
    public
    
    def version node, group
      with_lock do
        i = find_node_index node
        output = self[i].output.new
        raise Oxidized::NotSupported unless output.respond_to? :fetch
        output.version node, group
      end
    end
    
    def get_version node, group, oid
      with_lock do
        i = find_node_index node
        output = self[i].output.new
        raise Oxidized::NotSupported unless output.respond_to? :fetch
        output.get_version node, group, oid
      end
    end
    
    def get_diff node, group, oid1, oid2
      with_lock do
        i = find_node_index node
        output = self[i].output.new
        raise Oxidized::NotSupported unless output.respond_to? :fetch
        output.get_diff node, group, oid1, oid2
      end
    end

  end
end
