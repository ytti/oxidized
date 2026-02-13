module Oxidized
  module Source
    class SQL < Source
      begin
        require 'sequel'
      rescue LoadError
        raise OxidizedError, 'sequel not found: sudo gem install sequel'
      end

      def setup
        if @cfg.empty?
          Oxidized.asetus.user.source.sql.adapter   = 'sqlite'
          Oxidized.asetus.user.source.sql.database  = File.join(Config::ROOT, 'sqlite.db')
          Oxidized.asetus.user.source.sql.table     = 'devices'
          Oxidized.asetus.user.source.sql.map.name  = 'name'
          Oxidized.asetus.user.source.sql.map.model = 'rancid'
          Oxidized.asetus.save :user
          raise NoConfig, "No source sql config, edit #{Oxidized::Config.configfile}"
        end

        # map.name is mandatory
        return if @cfg.map.has_key?('name')

        raise InvalidConfig, "map/name is a mandatory source attribute, edit #{Oxidized::Config.configfile}"
      end

      def load(node_want = nil)
        nodes = []
        db = connect
        query = db[@cfg.table.to_sym]
        query = query.with_sql(@cfg.query) if @cfg.query?

        query = query.where(@cfg.map.name.to_sym => node_want) if node_want

        query.each do |node|
          # map node parameters
          keys = {}
          @cfg.map.each { |key, sql_column| keys[key.to_sym] = node_var_interpolate node[sql_column.to_sym] }
          keys[:model] = map_model keys[:model] if keys.has_key? :model
          keys[:group] = map_group keys[:group] if keys.has_key? :group

          # map node specific vars
          vars = {}
          @cfg.vars_map.each do |key, sql_column|
            vars[key.to_s] = node_var_interpolate node[sql_column.to_sym]
          end
          keys[:vars] = vars unless vars.empty?

          nodes << keys
        end
        db.disconnect
        nodes
      end

      private

      def initialize
        super
        @cfg = Oxidized.config.source.sql
      end

      def connect
        options = {
          adapter:  @cfg.adapter,
          host:     @cfg.host?,
          user:     @cfg.user?,
          password: @cfg.password?,
          database: @cfg.database,
          ssl_mode: @cfg.ssl_mode?
        }
        if @cfg.with_ssl?
          options.merge!(sslca:   @cfg.ssl_ca?,
                         sslcert: @cfg.ssl_cert?,
                         sslkey:  @cfg.ssl_key?)
        end
        Sequel.connect(options)
      rescue Sequel::AdapterNotFound => e
        raise OxidizedError, "SQL adapter gem not installed: " + e.message
      end
    end
  end
end
