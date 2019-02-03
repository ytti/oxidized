module Oxidized
  class Node
    class Stats
      attr_reader :mtimes
      MAX_STAT = 10

      # @param [Job] job job whose information add to stats
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

      # @param [Symbol] status stats for specific status
      # @return [Hash,Array] Hash of stats for every status or Array of stats for specific status
      def get(status = nil)
        status ? @stats[status] : @stats
      end

      def get_counter(counter = nil)
        counter ? @stats[:counter][counter] : @stats[:counter]
      end

      def successes
        @stats[:counter][:success]
      end

      def failures
        @stats[:counter].reduce(0) { |m, h| h[0] == :success ? m : m + h[1] }
      end

      def mtime
        mtimes.last
      end

      def update_mtime
        @mtimes.push Time.now.utc
        @mtimes.shift
      end

      private

      def initialize
        @history_size = Oxidized.config.stats.history_size? || MAX_STAT
        @mtimes = Array.new(@history_size, "unknown")
        @stats  = {}
        @stats[:counter] = Hash.new 0
      end
    end
  end
end
