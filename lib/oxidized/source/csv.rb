module Oxidized
  module Source
    class CSV < Source
      def initialize
        @cfg = Oxidized.config.source.csv
        super
      end

      def setup
        if @cfg.empty?
          Oxidized.asetus.user.source.csv.file      = File.join(Config::ROOT, 'router.db')
          Oxidized.asetus.user.source.csv.delimiter = /:/
          Oxidized.asetus.user.source.csv.map.name  = 0
          Oxidized.asetus.user.source.csv.map.model = 1
          Oxidized.asetus.user.source.csv.gpg       = false
          Oxidized.asetus.save :user
          raise NoConfig, "no source csv config, edit #{Oxidized::Config.configfile}"
        end
        require 'gpgme' if @cfg.gpg?

        # map.name is mandatory
        return if @cfg.map.has_key?('name')

        raise InvalidConfig, "map/name is a mandatory source attribute, edit #{Oxidized::Config.configfile}"
      end

      def load(_node_want = nil)
        nodes = []
        open_file.each_line do |line|
          next if line =~ /^\s*#/

          data = line.chomp.split(@cfg.delimiter, -1)
          next if data.empty?

          # map node parameters
          keys = {}
          @cfg.map.each do |key, position|
            keys[key.to_sym] = node_var_interpolate data[position]
          end
          keys[:model] = map_model keys[:model] if keys.has_key? :model
          keys[:group] = map_group keys[:group] if keys.has_key? :group

          # map node specific vars
          vars = {}
          @cfg.vars_map.each do |key, position|
            vars[key.to_sym] = node_var_interpolate data[position]
          end
          keys[:vars] = vars unless vars.empty?

          nodes << keys
        end
        nodes
      end
    end
  end
end
