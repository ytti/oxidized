module Oxidized
  module Output
    # Manages file-based output for configuration storage in Oxidized.
    #
    # This class extends the Output module and provides methods to
    # store and fetch configuration files.
    class OxidizedFile < Output
      require 'fileutils'

      attr_reader :commitref

      # Initializes the OxidizedFile instance.
      #
      # @return [void]
      def initialize
        super
        @cfg = Oxidized.config.output.file
      end

      # Sets up the output directory for configuration files.
      #
      # @raise [NoConfig] if no output file configuration is provided.
      # @return [void]
      def setup
        return unless @cfg.empty?

        Oxidized.asetus.user.output.file.directory = File.join(Config::ROOT, 'configs')
        Oxidized.asetus.save :user
        raise Error::NoConfig, "no output file config, edit #{Oxidized::Config.configfile}"
      end

      # Stores the configuration output for a specified node.
      #
      # @param node [Node] The node for which to store the configuration.
      # @param outputs [Object] The configuration outputs to store.
      # @param opt [Hash] Optional parameters for storage, such as group.
      # @return [void]
      def store(node, outputs, opt = {})
        file = File.expand_path @cfg.directory
        file = File.join File.dirname(file), opt[:group] if opt[:group]
        FileUtils.mkdir_p file
        file = File.join file, node
        File.write(file, outputs.to_cfg)
        @commitref = file
      end

      # Fetches the configuration for a specified node and group.
      #
      # @param node [Node] The node for which to fetch the configuration.
      # @param group [String] The group under which to look for the configuration.
      # @return [String, nil] The contents of the configuration file, or nil if not found.
      def fetch(node, group)
        cfg_dir   = File.expand_path @cfg.directory
        node_name = node.name

        if group # group is explicitly defined by user
          cfg_dir = File.join File.dirname(cfg_dir), group
          File.read File.join(cfg_dir, node_name)
        elsif File.exist? File.join(cfg_dir, node_name) # node configuration file is stored on base directory
          File.read File.join(cfg_dir, node_name)
        else
          path = Dir.glob(File.join(File.dirname(cfg_dir), '**', node_name)).first # fetch node in all groups
          File.read path
        end
      rescue Errno::ENOENT
        nil
      end
    end

      # Retrieves the version of a node's configuration.
      #
      # @param _node [Node] The node for which to retrieve the version.
      # @param _group [String] The group of the node.
      # @return [Array] An empty array, as versioning is not supported.
      # @note not supported
      def version(_node, _group)
        []
      end

      # Gets the version of a specific object ID for a node.
      #
      # @param _node [Node] The node for which to get the version.
      # @param _group [String] The group of the node.
      # @param _oid [String] The object ID for which to get the version.
      # @return [String] A message indicating versioning is not supported.
      # @note not supported
      def get_version(_node, _group, _oid)
        'not supported'
      end
    end
  end
end
