module Oxidized
  module Source
    # Manages the source of configuration data from a JSON file.
    #
    # This class handles loading device configurations from a specified JSON file,
    # including variable interpolation and mapping of node parameters.
    class JSONFile < Source
      require "json"
      # Initializes a new instance of the JSONFile class.
      #
      # This constructor sets up the configuration for the JSON file source.
      def initialize
        @cfg = Oxidized.config.source.jsonfile
        super
      end

      # Sets up the JSON file source configuration.
      #
      # If no configuration is provided, it initializes default settings
      # and raises an exception if the configuration is still empty.
      #
      # @raise [Error::NoConfig] If no source JSON configuration is found.
      def setup
        if @cfg.empty?
          Oxidized.asetus.user.source.jsonfile.file      = File.join(Oxidized::Config::ROOT,
                                                                     'router.json')
          Oxidized.asetus.user.source.jsonfile.map.name  = "name"
          Oxidized.asetus.user.source.jsonfile.map.model = "model"
          Oxidized.asetus.user.source.jsonfile.gpg       = false
          Oxidized.asetus.save :user
          raise Error::NoConfig, "No source json config, edit #{Oxidized::Config.configfile}"
        end
        require 'gpgme' if @cfg.gpg?

        # map.name is mandatory
        return if @cfg.map.has_key?('name')

        raise Error::InvalidConfig, "map/name is a mandatory source attribute, edit #{Oxidized::Config.configfile}"
      end

      # Loads the data from the configured JSON file.
      #
      # @return [Array<Hash>] An array of hashes representing the nodes,
      #   with parameters mapped according to the configuration.
      def load(*)
        data = JSON.parse(open_file.read)
        data = string_navigate_object(data, @cfg.hosts_location) if @cfg.hosts_location?

        transform_json(data)
      end

      private

      # Transforms the parsed JSON data into a structured format for nodes.
      #
      # @param data [Array] The parsed JSON data.
      # @return [Array<Hash>] An array of hashes representing the mapped nodes.
      def transform_json(data)
        nodes = []
        data.each do |node|
          next if node.empty?

          # @!visibility private
          # map node parameters
          keys = {}
          @cfg.map.each do |key, want_position|
            keys[key.to_sym] = node_var_interpolate string_navigate_object(node, want_position)
          end
          keys[:model] = map_model keys[:model] if keys.has_key? :model
          keys[:group] = map_group keys[:group] if keys.has_key? :group

          # @!visibility private
          # map node specific vars
          vars = {}
          @cfg.vars_map.each do |key, want_position|
            vars[key.to_sym] = node_var_interpolate string_navigate_object(node, want_position)
          end
          keys[:vars] = vars unless vars.empty?

          nodes << keys
        end
        nodes
      end
    end
  end
end
