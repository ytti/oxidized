module Oxidized
  # Represents a network node in Oxidized.
  class Node
    # Manages statistics related to jobs for a node.
    class Stats
      # @!attribute [rw] mtimes
      #   @return [Array] A history of modification times for the node.
      attr_reader :mtimes

      # The maximum number of job statistics to retain in history.
      #
      # This constant defines the limit for how many modification times
      # and job statistics are stored for a node.
      MAX_STAT = 10

      # Adds job information to the statistics.
      #
      # @param [Job] job The job whose information to add to stats.
      # @return [void]
      def add(job)
        stat = {
          start: job.start,
          end:   job.end,
          time:  job.time
        }
        @stats[job.status] ||= []
        @stats[job.status].shift if @stats[job.status].size > @history_size
        @stats[job.status].push stat
        @stats[:counter][job.status] += 1
      end

      # Retrieves statistics for the specified status or all statuses.
      #
      # @param [Symbol] status The status for which to get stats.
      # @return [Hash, Array] Hash of stats for every status or Array of stats for specific status.
      def get(status = nil)
        status ? @stats[status] : @stats
      end

      # Retrieves the count of jobs for a specific or all statuses.
      #
      # @param [Symbol] counter The specific status to get the count for.
      # @return [Integer, Hash] The count for the specific status or a Hash of counts for all statuses.
      def get_counter(counter = nil)
        counter ? @stats[:counter][counter] : @stats[:counter]
      end

      # Returns the count of successful jobs.
      #
      # @return [Integer] The number of successful jobs.
      def successes
        @stats[:counter][:success]
      end

      # Returns the count of failed jobs.
      #
      # @return [Integer] The number of failed jobs.
      def failures
        @stats[:counter].reduce(0) { |m, h| h[0] == :success ? m : m + h[1] }
      end

      # Retrieves the last modified time of the stats.
      #
      # @return [Time] The last modified time.
      def mtime
        mtimes.last
      end

      # Updates the last modified time to the current time.
      #
      # @return [void]
      def update_mtime
        @mtimes.push Time.now.utc
        @mtimes.shift
      end

      private

      # Initializes a new Stats object.
      #
      # @return [void]
      def initialize
        @history_size = Oxidized.config.stats.history_size? || MAX_STAT
        @mtimes = Array.new(@history_size, "unknown")
        @stats  = {}
        @stats[:counter] = Hash.new 0
      end
    end
  end
end
