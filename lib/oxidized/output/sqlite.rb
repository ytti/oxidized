module Oxidized
  module Output
    class SQLite < Output
      require 'sequel'
      require 'fileutils'

      attr_reader :commitref

      SCHEMA_VERSION = 1

      def initialize
        super
        @cfg = Oxidized.config.output.sqlite
      end

      def setup
        return unless @cfg.empty?

        Oxidized.asetus.user.output.sqlite.database = ::File.join(Config::ROOT, 'configs.db')
        Oxidized.asetus.save :user
        raise NoConfig, "no output sqlite config, edit #{Oxidized::Config.configfile}"
      end

      def open
        @db_path = ::File.expand_path(@cfg.database)
        ensure_database_directory
        connect_database
        migrate_schema
        secure_database_file
      end

      def close
        @db&.disconnect
      end

      # Store configuration for a node
      # @param node [String] Node name
      # @param outputs [Oxidized::Models::Outputs] Configuration outputs
      # @param opt [Hash] Options including :group
      def store(node, outputs, opt = {})
        open unless @db

        config_data = outputs.to_cfg
        group = opt[:group]

        @db.transaction do
          # Check if config exists
          existing = @db[:configs].where(node: node, group: group).first

          if existing
            # Update if changed
            if existing[:config] != config_data
              @db[:configs].where(node: node, group: group).update(
                config:     config_data,
                updated_at: Time.now.utc
              )
              add_version(node, group, config_data)
            end
          else
            # Insert new config
            @db[:configs].insert(
              node:       node,
              group:      group,
              config:     config_data,
              created_at: Time.now.utc,
              updated_at: Time.now.utc
            )
            add_version(node, group, config_data)
          end
        end

        @commitref = "#{node}:#{Time.now.utc.to_i}"
      end

      # Fetch configuration for a node
      # @param node [String] Node name
      # @param group [String] Group name
      # @return [String, nil] Configuration or nil if not found
      def fetch(node, group)
        open unless @db

        row = @db[:configs].where(node: node, group: group).first
        row ? row[:config] : nil
      end

      # Get version history for a node
      # @param node [String] Node name
      # @param group [String] Group name
      # @return [Array<Hash>] Version history with oid, date, and author
      def version(node, group)
        open unless @db

        @db[:config_versions]
          .where(node: node, group: group)
          .order(Sequel.desc(:created_at))
          .limit(100)
          .map do |row|
            {
              oid:    row[:id].to_s,
              date:   row[:created_at],
              author: 'oxidized'
            }
          end
      end

      # Get a specific version of configuration
      # @param node [String] Node name
      # @param group [String] Group name
      # @param oid [String] Version ID
      # @return [String] Configuration at that version
      def get_version(node, group, oid)
        open unless @db

        row = @db[:config_versions]
              .where(node: node, group: group, id: oid.to_i)
              .first

        row ? row[:config] : 'version not found'
      end

      # Clean up configurations for obsolete nodes
      # @param active_nodes [Array<Node>] List of active nodes
      def self.clean_obsolete_nodes(active_nodes)
        output = new
        output.open

        active_node_groups = active_nodes.map { |n| { node: n.name, group: n.group } }

        output.instance_variable_get(:@db).transaction do
          # Get all nodes in database
          db_nodes = output.instance_variable_get(:@db)[:configs]
                           .select(:node, :group)
                           .distinct
                           .all

          # Find obsolete nodes
          obsolete = db_nodes.reject do |db_node|
            active_node_groups.any? do |active|
              active[:node] == db_node[:node] && active[:group] == db_node[:group]
            end
          end

          # Delete obsolete nodes and their versions
          obsolete.each do |obs|
            output.instance_variable_get(:@db)[:configs]
                  .where(node: obs[:node], group: obs[:group])
                  .delete
            output.instance_variable_get(:@db)[:config_versions]
                  .where(node: obs[:node], group: obs[:group])
                  .delete
            logger.info "Cleaned up obsolete node: #{obs[:node]} (group: #{obs[:group]})"
          end
        end

        output.close
      end

      private

      def connect_database
        @db = Sequel.connect("sqlite://#{@db_path}")
        @db.logger = logger if Oxidized.config.debug?

        # Enable WAL mode for better concurrency
        @db.run("PRAGMA journal_mode=WAL")
        @db.run("PRAGMA synchronous=NORMAL")
        @db.run("PRAGMA foreign_keys=ON")
      end

      def migrate_schema
        # Create schema_info table if not exists
        @db.create_table?(:schema_info) do
          Integer :version, null: false
          DateTime :migrated_at, null: false
        end

        current_version = @db[:schema_info].max(:version) || 0

        return unless current_version < SCHEMA_VERSION

        logger.info "Migrating output SQLite database from version #{current_version} to #{SCHEMA_VERSION}"
        migrate_to_v1 if current_version < 1

        @db[:schema_info].insert(
          version:     SCHEMA_VERSION,
          migrated_at: Time.now.utc
        )
      end

      def migrate_to_v1
        # Create configs table
        @db.create_table?(:configs) do
          primary_key :id
          String :node, null: false, index: true
          String :group, index: true
          Text :config, null: false
          DateTime :created_at, null: false
          DateTime :updated_at, null: false

          index %i[node group], unique: true
        end

        # Create config versions table
        @db.create_table?(:config_versions) do
          primary_key :id
          String :node, null: false, index: true
          String :group, index: true
          Text :config, null: false
          DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP

          index %i[node group created_at]
        end
      end

      def add_version(node, group, config)
        @db[:config_versions].insert(
          node:       node,
          group:      group,
          config:     config,
          created_at: Time.now.utc
        )

        # Keep only last 100 versions per node/group
        count = @db[:config_versions]
                  .where(node: node, group: group)
                  .count

        return unless count > 100

        old_ids = @db[:config_versions]
                    .where(node: node, group: group)
                    .order(:created_at)
                    .limit(count - 100)
                    .select_map(:id)

        @db[:config_versions].where(id: old_ids).delete
      end

      def ensure_database_directory
        db_dir = ::File.dirname(@db_path)
        return if ::File.directory?(db_dir)

        FileUtils.mkdir_p(db_dir, mode: 0o700)
        logger.info "Created database directory: #{db_dir}"
      end

      def secure_database_file
        return unless ::File.exist?(@db_path)

        ::File.chmod(0o600, @db_path)
        [@db_path + '-wal', @db_path + '-shm'].each do |file|
          ::File.chmod(0o600, file) if ::File.exist?(file)
        end
      end
    end
  end
end
