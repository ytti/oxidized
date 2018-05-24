module Oxidized
  class Node
    class Stats
      MAX_STAT = 10

      # @param [Job] job job whose information add to stats
      # @return [void]
      def add job
        stat = {
          :start  => job.start,
          :end    => job.end,
          :time   => job.time,
        }
        @stats[job.status] ||= []
        @stats[job.status].shift if @stats[job.status].size > MAX_STAT
        @stats[job.status].push stat
        if job.status.equal? :success
          @stats[:success_count] += 1
        else
          @stats[:failure_count] += 1
        end
      end

      # @param [Symbol] status stats for specific status
      # @return [Hash,Array] Hash of stats for every status or Array of stats for specific status
      def get status = nil
        status ? @stats[status] : @stats
      end

      private

      def initialize
        @stats = {}
        @stats[:success_count] = 0
        @stats[:failure_count] = 0
      end
    end
  end
end
