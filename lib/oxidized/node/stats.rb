module Oxidized
  class Node
    # Node statistics with persistent SQLite storage
    # Replaces in-memory stats with database-backed state
    class Stats
      MAX_STAT = 10

      # Initialize stats for a specific node
      # @param [String] node_name Name of the node
      def initialize(node_name)
        @node_name = node_name
        @history_size = Oxidized.config.stats.history_size? || MAX_STAT
        @cache = nil
        @cache_time = nil
        @cache_ttl = 1 # Cache for 1 second to reduce DB queries
      end

      # @param [Job] job job whose information add to stats
      # @return [void]
      def add(job)
        Oxidized.state.update_node_stats(@node_name, job, @history_size)
        invalidate_cache
      end

      # @param [Symbol] status stats for specific status
      # @return [Hash,Array] Hash of stats for every status or Array of stats for specific status
      def get(status = nil)
        stats = load_stats
        status ? stats[status] : stats
      end

      def get_counter(counter = nil)
        stats = load_stats
        counter ? stats[:counter][counter] : stats[:counter]
      end

      def successes
        stats = load_stats
        stats[:counter][:success]
      end

      def failures
        stats = load_stats
        stats[:counter].reduce(0) { |m, h| h[0] == :success ? m : m + h[1] }
      end

      def mtimes
        stats = load_stats
        result = stats[:mtimes]
        # Maintain backward compatibility: pad with "unknown" if needed
        if result.length < @history_size
          result = result + Array.new(@history_size - result.length, "unknown")
        end
        result
      end

      def mtime
        mtimes.last
      end

      def update_mtime
        Oxidized.state.update_mtime(@node_name, @history_size)
        invalidate_cache
      end

      private

      def load_stats
        now = Time.now.to_f
        # Use cached data if available and fresh
        if @cache && @cache_time && (now - @cache_time) < @cache_ttl
          return @cache
        end

        @cache = Oxidized.state.get_node_stats(@node_name)
        @cache_time = now
        @cache
      end

      def invalidate_cache
        @cache = nil
        @cache_time = nil
      end
    end
  end
end
