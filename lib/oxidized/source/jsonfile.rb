module Oxidized
  class JSONFile < Source
    require "json"
    def initialize
      @cfg = Oxidized.config.source.jsonfile
      super
    end

    def setup
      if @cfg.empty?
        Oxidized.asetus.user.source.jsonfile.file      = File.join(Config::Root, 'router.json')
        Oxidized.asetus.user.source.jsonfile.map.name  = "name"
        Oxidized.asetus.user.source.jsonfile.map.model = "model"
        Oxidized.asetus.user.source.jsonfile.gpg       = false
        Oxidized.asetus.save :user
        raise NoConfig, 'No source json config, edit ~/.config/oxidized/config'
      end
      require 'gpgme' if @cfg.gpg?
    end

    def load(*)
      data = JSON.parse(open_file.read)
      data = string_navigate_object(data, @cfg.hosts_location) if @cfg.hosts_location?

      transform_json(data)
    end

    private

    def transform_json(data)
      nodes = []
      data.each do |node|
        next if node.empty?

        # map node parameters
        keys = {}
        @cfg.map.each do |key, want_position|
          keys[key.to_sym] = node_var_interpolate string_navigate_object(node, want_position)
        end
        keys[:model] = map_model keys[:model] if keys.has_key? :model
        keys[:group] = map_group keys[:group] if keys.has_key? :group

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
