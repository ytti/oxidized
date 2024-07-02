module Oxidized
  require 'ipaddr'
  require 'oxidized/node'
  class NotSupported < OxidizedError; end
  class NodeNotFound < OxidizedError; end

  class Nodes < Array
    attr_accessor :source, :jobs
    alias put unshift
    def load(node_want = nil)
      with_lock do
        new = []
        @source = Oxidized.config.source.default
        Oxidized.mgr.add_source(@source) || raise(MethodNotFound, "cannot load node source '#{@source}', not found")
        Oxidized.logger.info "lib/oxidized/nodes.rb: Loading nodes"
        nodes = Oxidized.mgr.source[@source].new.load node_want
        nodes.each do |node|
          # we want to load specific node(s), not all of them
          next unless node_want? node_want, node

          begin
            node_obj = Node.new node
            new.push node_obj
          rescue ModelNotFound => e
            Oxidized.logger.error "node %s raised %s with message '%s'" % [node, e.class, e.message]
          rescue Resolv::ResolvError => e
            Oxidized.logger.error "node %s is not resolvable, raised %s with message '%s'" % [node, e.class, e.message]
          end
        end
        size.zero? ? replace(new) : update_nodes(new)
        Oxidized.logger.info "lib/oxidized/nodes.rb: Loaded #{size} nodes"
      end
    end

    def node_want?(node_want, node)
      return true unless node_want

      node_want_ip = (IPAddr.new(node_want) rescue false)
      name_is_ip   = (IPAddr.new(node[:name]) rescue false)
      # rubocop:todo Lint/DuplicateBranch
      if name_is_ip && (node_want_ip == node[:name])
        true
      elsif node[:ip] && (node_want_ip == node[:ip])
        true
      elsif node_want.match node[:name]
        true unless name_is_ip
      end
      # rubocop:enable Lint/DuplicateBranch
    end

    def list
      with_lock do
        map { |e| e.serialize }
      end
    end

    def show(node)
      with_lock do
        i = find_node_index node
        self[i].serialize
      end
    end

    def fetch(node_name, group)
      yield_node_output(node_name) do |node, output|
        output.fetch node, group
      end
    end

    # @param node [String] name of the node moved into the head of array
    def next(node, opt = {})
      return unless waiting.find_node_index(node)

      with_lock do
        n = del node
        n.user = opt['user']
        n.email = opt['email']
        n.msg  = opt['msg']
        n.from = opt['from']
        # set last job to nil so that the node is picked for immediate update
        n.last = nil
        put n
        jobs.increment if Oxidized.config.next_adds_job?
      end
    end
    alias top next

    # @return [String] node from the head of the array
    def get
      with_lock do
        (self << shift).last
      end
    end

    # @param node node whose index number in Nodes to find
    # @return [Fixnum] index number of node in Nodes
    def find_node_index(node)
      find_index(node) || raise(NodeNotFound, "unable to find '#{node}'")
    end

    def version(node_name, group)
      yield_node_output(node_name) do |node, output|
        output.version node, group
      end
    end

    def get_version(node_name, group, oid)
      yield_node_output(node_name) do |node, output|
        output.get_version node, group, oid
      end
    end

    def get_diff(node_name, group, oid1, oid2)
      yield_node_output(node_name) do |node, output|
        output.get_diff node, group, oid1, oid2
      end
    end

    private

    def initialize(opts = {})
      super()
      node = opts.delete :node
      @mutex = Mutex.new # we compete for the nodes with webapi thread
      if (nodes = opts.delete(:nodes))
        replace nodes
      else
        load node
      end
    end

    def with_lock(...)
      @mutex.synchronize(...)
    end

    def find_index(node)
      index { |e| [e.name, e.ip].include? node }
    end

    # @param node node which is removed from nodes list
    # @return [Node] deleted node
    def del(node)
      delete_at find_node_index(node)
    end

    # @return [Nodes] list of nodes running now
    def running
      Nodes.new nodes: select { |node| node.running? }
    end

    # @return [Nodes] list of nodes waiting (not running)
    def waiting
      Nodes.new nodes: select { |node| not node.running? }
    end

    # walks list of new nodes, if old node contains same name, adds last and
    # stats information from old to new.
    #
    # @todo can we trust name to be unique identifier, what about when groups are used?
    # @param [Array] nodes Array of nodes used to replace+update old
    def update_nodes(nodes)
      old = dup
      # load the Array "nodes" in self (the class Nodes inherits Array)
      replace(nodes)
      each do |node|
        if (i = old.find_node_index(node.name))
          node.stats = old[i].stats
          node.last  = old[i].last
        end
      rescue NodeNotFound
        # Do nothing:
        # when a node is not found, we have nothing to do:
        # it has already been loaded by replace(nodes) and there are no
        # stats to copy
      end
      sort_by! { |x| x.last.nil? ? Time.new(0) : x.last.end }
    end

    def yield_node_output(node_name)
      with_lock do
        node = find { |n| n.name == node_name }
        raise(NodeNotFound, "unable to find '#{node_name}'") if node.nil?

        output = node.output.new
        raise NotSupported unless output.respond_to? :fetch

        yield node, output
      end
    end
  end
end
