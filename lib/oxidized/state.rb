module Oxidized
  # Persistent state management using SQLite
  # Replaces in-memory state storage for node statistics and job tracking
  class State
    include SemanticLogger::Loggable

    begin
      require 'sequel'
    rescue LoadError
      raise OxidizedError, 'sequel gem not found: sudo gem install sequel'
    end

    SCHEMA_VERSION = 1

    # Initialize the state database
    # @param database_path [String] Path to SQLite database file
    def initialize(database_path = nil)
      @database_path = database_path || default_database_path
      @db = nil
      connect
      migrate
    end

    # Get node statistics
    # @param node_name [String] Name of the node
    # @return [Hash] Statistics hash with job history and counters
    def get_node_stats(node_name)
      stats = {
        counter: Hash.new(0),
        mtimes: []
      }

      # Load counters
      @db[:node_stats_counters]
        .where(node_name: node_name)
        .each do |row|
          stats[:counter][row[:status].to_sym] = row[:count]
        end

      # Load job history grouped by status
      @db[:node_stats_history]
        .where(node_name: node_name)
        .order(:job_start)
        .each do |row|
          status = row[:status].to_sym
          stats[status] ||= []
          stats[status] << {
            start: row[:job_start],
            end: row[:job_end],
            time: row[:job_time]
          }
        end

      # Load mtimes
      stats[:mtimes] = @db[:node_mtimes]
        .where(node_name: node_name)
        .order(:mtime)
        .select_map(:mtime)

      stats
    end

    # Update node statistics with new job information
    # @param node_name [String] Name of the node
    # @param job [Object] Job object with start, end, time, and status
    # @param history_size [Integer] Maximum number of history items per status
    def update_node_stats(node_name, job, history_size = 10)
      @db.transaction do
        # Update counter
        counter = @db[:node_stats_counters]
          .where(node_name: node_name, status: job.status.to_s)
          .first

        if counter
          @db[:node_stats_counters]
            .where(node_name: node_name, status: job.status.to_s)
            .update(count: counter[:count] + 1)
        else
          @db[:node_stats_counters].insert(
            node_name: node_name,
            status: job.status.to_s,
            count: 1
          )
        end

        # Add job to history
        @db[:node_stats_history].insert(
          node_name: node_name,
          status: job.status.to_s,
          job_start: job.start,
          job_end: job.end,
          job_time: job.time
        )

        # Trim history to keep only the latest N entries per status
        trim_history(node_name, job.status.to_s, history_size)
      end
    end

    # Get the last job for a node
    # @param node_name [String] Name of the node
    # @return [Hash, nil] Last job information or nil
    def get_last_job(node_name)
      row = @db[:node_last_jobs]
        .where(node_name: node_name)
        .first

      return nil unless row

      {
        start: row[:job_start],
        end: row[:job_end],
        status: row[:status].to_sym,
        time: row[:job_time]
      }
    end

    # Set the last job for a node
    # @param node_name [String] Name of the node
    # @param job [Object, nil] Job object or nil to clear
    def set_last_job(node_name, job)
      @db.transaction do
        @db[:node_last_jobs].where(node_name: node_name).delete

        if job
          @db[:node_last_jobs].insert(
            node_name: node_name,
            job_start: job.start,
            job_end: job.end,
            status: job.status.to_s,
            job_time: job.time
          )
        end
      end
    end

    # Update modification time for a node
    # @param node_name [String] Name of the node
    # @param history_size [Integer] Maximum number of mtimes to keep
    def update_mtime(node_name, history_size = 10)
      @db.transaction do
        @db[:node_mtimes].insert(
          node_name: node_name,
          mtime: Time.now.utc
        )

        # Trim old mtimes
        count = @db[:node_mtimes]
          .where(node_name: node_name)
          .count

        if count > history_size
          old_records = @db[:node_mtimes]
            .where(node_name: node_name)
            .order(:mtime)
            .limit(count - history_size)
            .select_map(:id)

          @db[:node_mtimes]
            .where(id: old_records)
            .delete
        end
      end
    end

    # Get job durations for scheduling
    # @return [Array<Float>] Array of job durations
    def get_job_durations
      @db[:job_durations]
        .order(:created_at)
        .select_map(:duration)
    end

    # Add a job duration
    # @param duration [Float] Job duration in seconds
    # @param max_size [Integer] Maximum number of durations to keep
    def add_job_duration(duration, max_size)
      @db.transaction do
        @db[:job_durations].insert(
          duration: duration,
          created_at: Time.now.utc
        )

        # Trim old durations
        count = @db[:job_durations].count
        if count > max_size
          old_records = @db[:job_durations]
            .order(:created_at)
            .limit(count - max_size)
            .select_map(:id)

          @db[:job_durations]
            .where(id: old_records)
            .delete
        end
      end
    end

    # Clean up state for removed nodes
    # @param existing_nodes [Array<String>] List of current node names
    def cleanup_removed_nodes(existing_nodes)
      @db.transaction do
        tables = [:node_stats_counters, :node_stats_history, :node_last_jobs, :node_mtimes]
        tables.each do |table|
          @db[table].exclude(node_name: existing_nodes).delete
        end
      end
      logger.info "Cleaned up state for removed nodes"
    end

    # Close database connection
    def close
      @db&.disconnect
      @db = nil
    end

    # Reset all state (for testing)
    def reset!
      return unless @db

      @db.transaction do
        @db[:node_stats_counters].delete
        @db[:node_stats_history].delete
        @db[:node_last_jobs].delete
        @db[:node_mtimes].delete
        @db[:job_durations].delete
      end
      logger.info "Reset all state data"
    end

    private

    # Get default database path
    # @return [String] Path to database file
    def default_database_path
      state_dir = File.join(Config::ROOT, 'state')
      FileUtils.mkdir_p(state_dir) unless File.directory?(state_dir)
      File.join(state_dir, 'oxidized.db')
    end

    # Connect to database
    def connect
      logger.info "Connecting to state database: #{@database_path}"
      @db = Sequel.connect("sqlite://#{@database_path}")
      @db.logger = logger if Oxidized.config.debug?
      
      # Enable WAL mode for better concurrency
      @db.run("PRAGMA journal_mode=WAL")
      # Set synchronous to NORMAL for better performance while maintaining durability
      @db.run("PRAGMA synchronous=NORMAL")
      # Enable foreign keys
      @db.run("PRAGMA foreign_keys=ON")
    rescue Sequel::DatabaseConnectionError => e
      raise OxidizedError, "Failed to connect to state database: #{e.message}"
    end

    # Migrate database schema
    def migrate
      @db.create_table?(:schema_info) do
        Integer :version, null: false
        DateTime :migrated_at, null: false
      end

      current_version = @db[:schema_info].max(:version) || 0

      if current_version < SCHEMA_VERSION
        logger.info "Migrating state database from version #{current_version} to #{SCHEMA_VERSION}"
        migrate_to_v1 if current_version < 1
        
        @db[:schema_info].insert(
          version: SCHEMA_VERSION,
          migrated_at: Time.now.utc
        )
      end
    end

    # Migrate to schema version 1
    def migrate_to_v1
      # Node statistics counters
      @db.create_table?(:node_stats_counters) do
        primary_key :id
        String :node_name, null: false, index: true
        String :status, null: false
        Integer :count, null: false, default: 0
        
        index [:node_name, :status], unique: true
      end

      # Node statistics history
      @db.create_table?(:node_stats_history) do
        primary_key :id
        String :node_name, null: false, index: true
        String :status, null: false
        DateTime :job_start
        DateTime :job_end
        Float :job_time
        DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
        
        index [:node_name, :status]
        index :created_at
      end

      # Node last jobs
      @db.create_table?(:node_last_jobs) do
        primary_key :id
        String :node_name, null: false, unique: true, index: true
        DateTime :job_start
        DateTime :job_end
        String :status, null: false
        Float :job_time
        DateTime :updated_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      end

      # Node modification times
      @db.create_table?(:node_mtimes) do
        primary_key :id
        String :node_name, null: false, index: true
        DateTime :mtime, null: false
        
        index [:node_name, :mtime]
      end

      # Job durations for scheduling
      @db.create_table?(:job_durations) do
        primary_key :id
        Float :duration, null: false
        DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
        
        index :created_at
      end
    end

    # Trim history for a specific node and status
    # @param node_name [String] Name of the node
    # @param status [String] Job status
    # @param max_size [Integer] Maximum number of entries to keep
    def trim_history(node_name, status, max_size)
      count = @db[:node_stats_history]
        .where(node_name: node_name, status: status)
        .count

      return unless count > max_size

      # Get IDs of old records to delete
      old_records = @db[:node_stats_history]
        .where(node_name: node_name, status: status)
        .order(:job_start)
        .limit(count - max_size)
        .select_map(:id)

      @db[:node_stats_history]
        .where(id: old_records)
        .delete
    end
  end
end
