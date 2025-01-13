module Oxidized
  module Source
    class Source
      class NoConfig < OxidizedError; end

      # @see Oxidized.config
      def initialize
        @model_map = Oxidized.config.model_map || {}
        @group_map = Oxidized.config.group_map || {}
      end

      ##
      # Maps an original value to a new value based on a hash of mapping rules.
      #
      # This method iterates through a mapping hash and attempts to match the original value
      # against each key using either regular expression matching or direct equality.
      #
      # @param [Hash] map_hash A hash containing mapping rules where keys can be Regexp or other objects
      # @param [Object] original_value The value to be mapped
      # @return [Object] The mapped value if a match is found, otherwise the original value
      #
      # @example Mapping with regular expression
      #   map_value({/^web/ => 'web_server'}, 'web01') # Returns 'web_server'
      #
      # @example Mapping with direct equality
      #   map_value({'old_name' => 'new_name'}, 'old_name') # Returns 'new_name'
      #
      # @example No match scenario
      #   map_value({/^db/ => 'database'}, 'web01') # Returns 'web01'
      def map_value(map_hash, original_value)
        map_hash.each do |key, new_value|
          mthd = key.instance_of?(Regexp) ? :match : :eql?
          return new_value if original_value.send(mthd, key)
        end
        original_value
      end

      # @return [String] The mapped model name, or the original model if no mapping exists.
      def map_model(model)
        map_value(@model_map, model)
      end

      # @return [String] The mapped group name or the original group if no mapping exists.
      def map_group(group)
        map_value(@group_map, group)
      end

      ##
      # Interpolates a string representation of a variable to its corresponding Ruby value.
      #
      # This method converts string representations of boolean and nil values to their
      # respective Ruby types. It handles the following conversions:
      # - "nil" becomes nil
      # - "false" becomes false
      # - "true" becomes true
      # - Any other string value is returned as-is
      #
      # @param [String] var The string to be interpolated
      # @return [Object] The interpolated value (nil, false, true, or the original string)
      # @example
      #   node_var_interpolate("nil")   # => nil
      #   node_var_interpolate("false") # => false
      #   node_var_interpolate("true")  # => true
      #   node_var_interpolate("hello") # => "hello"
      def node_var_interpolate(var)
        case var
        when "nil"   then nil
        when "false" then false
        when "true"  then true
        else var
        end
      end

      private

      def open_file
        file = File.expand_path(@cfg.file)
        if @cfg.gpg?
          crypto = GPGME::Crypto.new password: @cfg.gpg_password
          crypto.decrypt(File.open(file)).to_s
        else
          File.open(file)
        end
      end

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
