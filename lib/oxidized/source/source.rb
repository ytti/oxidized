module Oxidized
  module Source
    # Manages the source of configuration data for Oxidized.
    #
    # This class is responsible for mapping models and groups, as well as
    # handling variable interpolation and file operations related to configuration sources.
    class Source
      require 'oxidized/error/noconfig'

      # Initializes a new instance of the Source class.
      #
      # This constructor sets up the model and group mappings based on
      # the current Oxidized configuration.
      def initialize
        @model_map = Oxidized.config.model_map || {}
        @group_map = Oxidized.config.group_map || {}
      end

      # Maps a model name to its corresponding configuration.
      #
      # @param model [String] The name of the model to map.
      # @return [String] The mapped model name, or the original model name
      #   if no mapping exists.
      def map_model(model)
        @model_map.has_key?(model) ? @model_map[model] : model
      end

      # Maps a group name to its corresponding configuration.
      #
      # @param group [String] The name of the group to map.
      # @return [String] The mapped group name, or the original group name
      #   if no mapping exists.
      def map_group(group)
        @group_map.has_key?(group) ? @group_map[group] : group
      end

      # Interpolates a variable string into its appropriate value.
      #
      # @param var [String] The variable string to interpolate.
      # @return [nil, Boolean, String] The interpolated value, which could be
      #   nil, a Boolean, or the original string if no special case applies.
      def node_var_interpolate(var)
        case var
        when "nil"   then nil
        when "false" then false
        when "true"  then true
        else var
        end
      end

      private

      # Opens a configuration file and decrypts it if necessary.
      #
      # @return [String, File] The decrypted file content or the file object.
      def open_file
        file = File.expand_path(@cfg.file)
        if @cfg.gpg?
          crypto = GPGME::Crypto.new password: @cfg.gpg_password
          crypto.decrypt(File.open(file)).to_s
        else
          File.open(file)
        end
      end

      # Navigates through an object based on a string path.
      #
      # @param object [Object] The object to navigate through.
      # @param wants [String] The path to navigate, specified as a string
      #   (e.g., "a.b[0].c").
      # @return [Object] The object at the end of the navigation path, or
      #   nil if the path is invalid.
      def string_navigate_object(object, wants)
        wants = wants.split(".").map do |want|
          head, match, _tail = want.partition(/\[\d+\]/)
          match.empty? ? head : [head, match[1..-2].to_i]
        end
        wants.flatten.each do |want|
          object = object[want] if object.respond_to? :each
        end
        object
      end
    end
  end
end
