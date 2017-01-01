module Oxidized
  class Node
    class Stats
      MAX_STAT = 10

      # @param [Job] job job whose information add to stats
      # @return [void]
      def add job
        status = job.stats.dup
        stat   = {
          :start  => job.start.dup,
          :end    => job.end.dup,
          :time   => job.time.dup,
        }
        @stats[status] ||= []
        @stats[status].shift if @stats[status].size > MAX_STAT
        @stats[status].push stat
      end

      # @param [Symbol] status stats for specific status
      # @return [Hash,Array] Hash of stats for every status or Array of stats for specific status
      def get status=nil
        status ? @stats[status] : @stats
      end

      private

      def initialize
        @stats = {}
      end

    end
  end
end
