module Oxidized
  require 'ipaddr'
  require 'oxidized/node'
  require 'oxidized/error/notsupported'
  require 'oxidized/error/nodenotfound'

  # Represents a collection of network nodes in the Oxidized system.
  class Nodes < Array
    # @!attribute [rw] source
    #   @return [String] The source from which nodes are loaded.
    attr_accessor :source

    # @!attribute [rw] jobs
    #   @return [Array<Job>] The jobs associated with the nodes.
    attr_accessor :jobs
    alias put unshift

    # Loads nodes from the configured source.
    #
    # @param node_want [String, nil] The specific node(s) to load (optional).
    # @return [void]
    def load(node_want = nil)
      with_lock do
        new = []
        @source = Oxidized.config.source.default
        Oxidized.mgr.add_source(@source) || raise(MethodNotFound, "cannot load node source '#{@source}', not found")
        Oxidized.logger.info "lib/oxidized/nodes.rb: Loading nodes"
        nodes = Oxidized.mgr.source[@source].new.load node_want
        nodes.each do |node|
          # @!visibility private
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

    # Checks if a node matches the specified criteria.
    #
    # @param node_want [String, nil] The criteria to match against.
    # @param node [Hash{Symbol => Object}] The node to check.
    # @return [Boolean] True if the node matches, false otherwise.
    def node_want?(node_want, node)
      return true unless node_want

      node_want_ip = (IPAddr.new(node_want) rescue false)
      name_is_ip   = (IPAddr.new(node[:name]) rescue false)
      # @!visibility private
      # rubocop:todo Lint/DuplicateBranch
      if name_is_ip && (node_want_ip == node[:name])
        true
      elsif node[:ip] && (node_want_ip == node[:ip])
        true
      elsif node_want.match node[:name]
        true unless name_is_ip
      end
      # @!visibility private
      # rubocop:enable Lint/DuplicateBranch
    end

    # Lists all nodes in a serialized format.
    #
    # @return [Array<Hash>] The serialized node information.
    def list
      with_lock do
        map { |e| e.serialize }
      end
    end

    # Shows the serialized information of a specific node.
    #
    # @param node [String] The name of the node to show.
    # @return [Hash] The serialized node information.
    def show(node)
      with_lock do
        i = find_node_index node
        self[i].serialize
      end
    end

    # Fetches the output for a specific node.
    #
    # @param node_name [String] The name of the node.
    # @param group [String] The group associated with the node.
    # @yield [node, output] Yields the node and its output object.
    def fetch(node_name, group)
      yield_node_output(node_name) do |node, output|
        output.fetch node, group
      end
    end

    # Moves a node to the head of the array for processing.
    #
    # @param node [String] The name of the node to move.
    # @param opt [Hash{String => Object}] Options for updating the node.
    # @return [void]
    def next(node, opt = {})
      return if running.find_index(node)

      with_lock do
        n = del node
        n.user = opt['user']
        n.email = opt['email']
        n.msg  = opt['msg']
        n.from = opt['from']
        # @!visibility private
        # set last job to nil so that the node is picked for immediate update
        n.last = nil
        put n
        jobs.increment if Oxidized.config.next_adds_job?
      end
    end
    alias top next

    # Retrieves and removes the node from the head of the array.
    #
    # @return [Node] The node from the head of the array.
    def get
      with_lock do
        (self << shift).last
      end
    end

    # Finds the index of a node in the array.
    #
    # @param node [String] The name or IP of the node.
    # @return [Integer] The index of the node in the array.
    def find_node_index(node)
      find_index(node) || raise(NodeNotFound, "unable to find '#{node}'")
    end

    # Retrieves the version of a specific node.
    #
    # @param node_name [String] The name of the node.
    # @param group [String] The group associated with the node.
    # @yield [node, output] Yields the node and its output object.
    def version(node_name, group)
      yield_node_output(node_name) do |node, output|
        output.version node, group
      end
    end

    # Gets the version of a specific node and its group.
    #
    # @param node_name [String] The name of the node.
    # @param group [String] The group associated with the node.
    # @param oid [String] The object ID.
    # @yield [node, output] Yields the node and its output object.
    def get_version(node_name, group, oid)
      yield_node_output(node_name) do |node, output|
        output.get_version node, group, oid
      end
    end

    # Gets the difference between two versions of a node.
    #
    # @param node_name [String] The name of the node.
    # @param group [String] The group associated with the node.
    # @param oid1 [String] The first object ID.
    # @param oid2 [String] The second object ID.
    # @yield [node, output] Yields the node and its output object.
    def get_diff(node_name, group, oid1, oid2)
      yield_node_output(node_name) do |node, output|
        output.get_diff node, group, oid1, oid2
      end
    end

    # Finds the index of a node in the array.
    #
    # @param node [String] The name or IP of the node.
    # @return [Integer] The index of the node in the array.
    def find_index(node)
      index { |e| [e.name, e.ip].include? node }
    end

    private

    # Initializes the Nodes collection.
    #
    # @param opts [Hash{Symbol => Object}] Options for initialization.
    # @option opts [String] :node The specific node to initialize (optional).
    # @option opts [Array<Node>] :nodes Existing nodes to load (optional).
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

    # Synchronizes access to the Nodes collection.
    #
    # @yield [void] The block to execute with a lock.
    def with_lock(...)
      @mutex.synchronize(...)
    end

    # Deletes a node from the collection.
    #
    # @param node [String] The name of the node to delete.
    # @return [Node] The deleted node.
    def del(node)
      delete_at find_node_index(node)
    end

    # Retrieves nodes that are currently running.
    #
    # @return [Nodes] List of running nodes.
    def running
      Nodes.new nodes: select { |node| node.running? }
    end

    # Retrieves nodes that are currently waiting (not running).
    #
    # @return [Nodes] List of waiting nodes.
    def waiting
      Nodes.new nodes: select { |node| not node.running? }
    end

    # Updates nodes with information from the old collection.
    #
    # @todo can we trust name to be unique identifier, what about when groups are used?
    # @param nodes [Array<Node>] The new array of nodes.
    # @return [void]
    def update_nodes(nodes)
      old = dup
      # @!visibility private
      # load the Array "nodes" in self (the class Nodes inherits Array)
      replace(nodes)
      each do |node|
        if (i = old.find_node_index(node.name))
          node.stats = old[i].stats
          node.last  = old[i].last
        end
      rescue NodeNotFound
        # @!visibility private
        # Do nothing:
        # when a node is not found, we have nothing to do:
        # it has already been loaded by replace(nodes) and there are no
        # stats to copy
      end
      sort_by! { |x| x.last.nil? ? Time.new(0) : x.last.end }
    end

    # Yields the output for a specified node.
    #
    # @param node_name [String] The name of the node.
    # @yield [node, output] Yields the node and its output object.
    def yield_node_output(node_name)
      with_lock do
        node = find { |n| n.name == node_name }
        raise(Error::NodeNotFound, "unable to find '#{node_name}'") if node.nil?

        output = node.output.new
        raise Error::NotSupported unless output.respond_to? :fetch

        yield node, output
      end
    end
  end
end
