module Oxidized
  class SQL < Source
    begin
      require 'sequel'
    rescue LoadError
      raise OxidizedError, 'sequel not found: sudo gem install sequel'
    end

    def setup
      return unless @cfg.empty?

      Oxidized.asetus.user.source.sql.adapter   = 'sqlite'
      Oxidized.asetus.user.source.sql.database  = File.join(Config::Root, 'sqlite.db')
      Oxidized.asetus.user.source.sql.table     = 'devices'
      Oxidized.asetus.user.source.sql.map.name  = 'name'
      Oxidized.asetus.user.source.sql.map.model = 'rancid'
      Oxidized.asetus.save :user
      raise NoConfig, 'no source sql config, edit ~/.config/oxidized/config'
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

        # map node specific vars
        vars = {}
        @cfg.vars_map.each do |key, sql_column|
          vars[key.to_sym] = node_var_interpolate node[sql_column.to_sym]
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
      Sequel.connect(adapter:  @cfg.adapter,
                     host:     @cfg.host?,
                     user:     @cfg.user?,
                     password: @cfg.password?,
                     database: @cfg.database)
    rescue Sequel::AdapterNotFound => error
      raise OxidizedError, "SQL adapter gem not installed: " + error.message
    end
  end
end
