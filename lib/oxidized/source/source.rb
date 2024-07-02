module Oxidized
  class Source
    class NoConfig < OxidizedError; end

    def initialize
      @model_map = Oxidized.config.model_map || {}
      @group_map = Oxidized.config.group_map || {}
    end

    def map_model(model)
      @model_map.has_key?(model) ? @model_map[model] : model
    end

    def map_group(group)
      @group_map.has_key?(group) ? @group_map[group] : group
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
