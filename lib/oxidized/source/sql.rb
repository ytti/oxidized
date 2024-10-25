module Oxidized
  module Source
    # The SQL class serves as a source for device data, using a SQL database.
    # It utilizes the Sequel gem to connect and interact with the database.
    class SQL < Source
      begin
        require 'sequel'
      rescue LoadError
        raise OxidizedError, 'sequel not found: sudo gem install sequel'
      end

    # Sets up the SQL source configuration with default values if none are provided.
    #
    # @return [void]
    # @raise [NoConfig] If no SQL source configuration is found.
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

      # Loads nodes from the SQL database based on the specified configuration.
      #
      # @param node_want [String, nil] The specific node to load; if nil, all nodes are loaded.
      # @return [Array<Hash>] An array of node data hashes.
      def load(node_want = nil)
        nodes = []
        db = connect
        query = db[@cfg.table.to_sym]
        query = query.with_sql(@cfg.query) if @cfg.query?

        query = query.where(@cfg.map.name.to_sym => node_want) if node_want

        query.each do |node|
          # @!visibility private
          # map node parameters
          keys = {}
          @cfg.map.each { |key, sql_column| keys[key.to_sym] = node_var_interpolate node[sql_column.to_sym] }
          keys[:model] = map_model keys[:model] if keys.has_key? :model
          keys[:group] = map_group keys[:group] if keys.has_key? :group

          # @!visibility private
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

      # Initializes the SQL source configuration.
      def initialize
        super
        @cfg = Oxidized.config.source.sql
      end

      # Connects to the SQL database using the specified configuration options.
      #
      # @return [Sequel::Database] The connected database object.
      # @raise [OxidizedError] If the SQL adapter gem is not installed.
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
