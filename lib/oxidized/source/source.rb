module Oxidized
  module Source
    class Source
      class NoConfig < OxidizedError; end

      def initialize
        @model_map = Oxidized.config.model_map || {}
        @group_map = Oxidized.config.group_map || {}
      end

      # common code of #map_model and #map_group
      def map_value(map_hash, original_value)
        map_hash.each do |key, new_value|
          mthd = key.instance_of?(Regexp) ? :match : :eql?
          return new_value if original_value.send(mthd, key)
        end
        original_value
      end

      # search a match for model in the configuration and returns it.
      # If no match is found, return model
      #
      # model can be matched against a string or a regexp:
      #
      # model_map:
      #   cisco: ios
      #   juniper: junos
      #   !ruby/regexp /procurve/: procurve
      def map_model(model)
        map_value(@model_map, model)
      end

      # search a match for group in the configuration and returns it.
      # If no match is found, return group
      #
      # group can be matched against a string or a regexp:
      #
      # group_map:
      #   alias1: groupA
      #   alias2: groupA
      #   alias3: groupB
      #   alias4: groupB
      #   !ruby/regexp /specialgroup/: groupS
      #   aliasN: groupZ
      def map_group(group)
        map_value(@group_map, group)
      end

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
