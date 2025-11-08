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
      ensure_secure_directory
      connect
      migrate
      secure_database_file
    end

    # Get node statistics
    # @param node_name [String] Name of the node
    # @return [Hash] Statistics hash with job history and counters
    def get_node_stats(node_name)
      stats = {
        counter: Hash.new(0),
        mtimes:  []
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
            end:   row[:job_end],
            time:  row[:job_time]
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
      validate_node_name!(node_name)
      validate_job!(job)
      validate_positive_integer!(history_size, 'history_size')

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
            status:    job.status.to_s,
            count:     1
          )
        end

        # Add job to history with validated data
        @db[:node_stats_history].insert(
          node_name: node_name,
          status:    job.status.to_s,
          job_start: ensure_time(job.start),
          job_end:   ensure_time(job.end),
          job_time:  ensure_float(job.time)
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
        start:  row[:job_start],
        end:    row[:job_end],
        status: row[:status].to_sym,
        time:   row[:job_time]
      }
    end

    # Set the last job for a node
    # @param node_name [String] Name of the node
    # @param job [Object, nil] Job object or nil to clear
    def set_last_job(node_name, job)
      validate_node_name!(node_name)
      validate_job!(job) if job

      @db.transaction do
        @db[:node_last_jobs].where(node_name: node_name).delete

        if job
          @db[:node_last_jobs].insert(
            node_name: node_name,
            job_start: ensure_time(job.start),
            job_end:   ensure_time(job.end),
            status:    job.status.to_s,
            job_time:  ensure_float(job.time)
          )
        end
      end
    end

    # Update modification time for a node
    # @param node_name [String] Name of the node
    # @param history_size [Integer] Maximum number of mtimes to keep
    def update_mtime(node_name, history_size = 10)
      validate_node_name!(node_name)
      validate_positive_integer!(history_size, 'history_size')

      @db.transaction do
        @db[:node_mtimes].insert(
          node_name: node_name,
          mtime:     Time.now.utc
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
    def job_durations
      @db[:job_durations]
        .order(:created_at)
        .select_map(:duration)
    end

    # Add a job duration
    # @param duration [Float] Job duration in seconds
    # @param max_size [Integer] Maximum number of durations to keep
    def add_job_duration(duration, max_size)
      validate_positive_number!(duration, 'duration')
      validate_positive_integer!(max_size, 'max_size')

      @db.transaction do
        @db[:job_durations].insert(
          duration:   ensure_float(duration),
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
        tables = %i[node_stats_counters node_stats_history node_last_jobs node_mtimes]
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

      return unless current_version < SCHEMA_VERSION

      logger.info "Migrating state database from version #{current_version} to #{SCHEMA_VERSION}"
      migrate_to_v1 if current_version < 1

      @db[:schema_info].insert(
        version:     SCHEMA_VERSION,
        migrated_at: Time.now.utc
      )
    end

    # Migrate to schema version 1
    def migrate_to_v1
      # Node statistics counters
      @db.create_table?(:node_stats_counters) do
        primary_key :id
        String :node_name, null: false, index: true
        String :status, null: false
        Integer :count, null: false, default: 0

        index %i[node_name status], unique: true
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

        index %i[node_name status]
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

        index %i[node_name mtime]
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

      old_records = @db[:node_stats_history]
                      .where(node_name: node_name, status: status)
                      .order(:job_start)
                      .limit(count - max_size)
                      .select_map(:id)

      @db[:node_stats_history]
        .where(id: old_records)
        .delete
    end

    # Validation and security methods

    # Ensure directory exists and has secure permissions
    def ensure_secure_directory
      state_dir = File.dirname(@database_path)
      return if File.directory?(state_dir)

      FileUtils.mkdir_p(state_dir, mode: 0o700)
      logger.info "Created state directory with secure permissions: #{state_dir}"
    end
    end

    # Set secure permissions on database file
    def secure_database_file
      return unless File.exist?(@database_path)

      # Set file permissions to 0600 (owner read/write only)
      File.chmod(0o600, @database_path)

      # Also secure WAL and SHM files if they exist
      [@database_path + '-wal', @database_path + '-shm'].each do |file|
        File.chmod(0o600, file) if File.exist?(file)
      end

      logger.info "Secured database file permissions: #{@database_path}"
    end

    # Validate node name
    # @param node_name [String] Node name to validate
    # @raise [ArgumentError] if node name is invalid
    def validate_node_name!(node_name)
      raise ArgumentError, "node_name cannot be nil" if node_name.nil?
      raise ArgumentError, "node_name must be a String" unless node_name.is_a?(String)
      raise ArgumentError, "node_name cannot be empty" if node_name.empty?
      raise ArgumentError, "node_name too long (max 255 chars)" if node_name.length > 255
    end

    # Validate job object
    # @param job [Object] Job object to validate
    # @raise [ArgumentError] if job is invalid
    def validate_job!(job)
      raise ArgumentError, "job cannot be nil" if job.nil?
      raise ArgumentError, "job must respond to :start" unless job.respond_to?(:start)
      raise ArgumentError, "job must respond to :end" unless job.respond_to?(:end)
      raise ArgumentError, "job must respond to :time" unless job.respond_to?(:time)
      raise ArgumentError, "job must respond to :status" unless job.respond_to?(:status)
    end

    # Validate positive integer
    # @param value [Integer] Value to validate
    # @param name [String] Name of the parameter
    # @raise [ArgumentError] if value is invalid
    def validate_positive_integer!(value, name)
      raise ArgumentError, "#{name} must be an Integer" unless value.is_a?(Integer)
      raise ArgumentError, "#{name} must be positive" unless value.positive?
    end

    # Validate positive number
    # @param value [Numeric] Value to validate
    # @param name [String] Name of the parameter
    # @raise [ArgumentError] if value is invalid
    def validate_positive_number!(value, name)
      raise ArgumentError, "#{name} must be a number" unless value.is_a?(Numeric)
      raise ArgumentError, "#{name} must be positive" unless value.positive?
      raise ArgumentError, "#{name} must be finite" unless value.finite?
    end

    # Ensure value is a Time object
    # @param value [Time, nil] Value to convert
    # @return [Time, nil] Time object or nil
    def ensure_time(value)
      return nil if value.nil?
      return value if value.is_a?(Time)

      # Try to parse if it's a string or convert if it's numeric
      if value.is_a?(String)
        Time.parse(value)
      elsif value.is_a?(Numeric)
        Time.at(value)
      else
        raise ArgumentError, "Cannot convert #{value.class} to Time"
      end
    rescue ArgumentError => e
      raise ArgumentError, "Invalid time value: #{e.message}"
    end

    # Ensure value is a Float
    # @param value [Numeric] Value to convert
    # @return [Float] Float value
    def ensure_float(value)
      return nil if value.nil?

      float_val = Float(value)
      raise ArgumentError, "Value must be finite" unless float_val.finite?

      float_val
    rescue TypeError, ArgumentError => e
      raise ArgumentError, "Invalid numeric value: #{e.message}"
    end
  end
end
