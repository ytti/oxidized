module Oxidized
  class Node
    class Stats
      require 'sequel'
      
      MAX_STAT = 10

      @@last_store = Hash.new # somewhere to store last information with no sql db

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
        store job
      end

      # @param [Symbol] status stats for specific status
      # @return [Hash,Array] Hash of stats for every status or Array of stats for specific status
      def get status=nil
        status ? @stats[status] : @stats
      end
      
      def fetch
        r = nil
        if sqlcfg.empty?
        # no sql config - fetch from memory
          unless @@last_store[@group].nil?
            r = OpenStruct.new(@@last_store[@group][@name]) unless @@last_store[@group][@name].nil?
          end
        else
          # sql config - fetch from db
          db = connect
          check_stats_table db
          stats = db[(sqlcfg.table + '_stats').to_sym].where(:name => @name, :group => @group).select( :start, :end, :time, :status).all
          r = OpenStruct.new(stats.first) unless stats.empty?
          db.disconnect
        end
        r
      end

      def store job
        if sqlcfg.empty?
          # no sql config - store in memory
          @@last_store[@group] = Hash.new if @@last_store[@group].nil?
          @@last_store[@group][@name] = { :start => job.start, :end => job.end, :time => job.time, :status => job.status }
        else
          # sql config - persist in db
          db = connect
          check_stats_table db
          begin
            query = db[(sqlcfg.table + '_stats').to_sym].insert( :name => @name, :group => @group, :start => job.start, :end => job.end, :time => job.time, :status => job.status.to_s )
          rescue Sequel::UniqueConstraintViolation
            query = db[(sqlcfg.table + '_stats').to_sym].where( :name => @name, :group => @group).update(:start => job.start, :end => job.end, :time => job.time, :status => job.status.to_s )
          end
          db.disconnect
        end
      end

      private

      def initialize
        @stats = {}
        @name = name
        @group = group
      end

      def sqlcfg
        CFG.source.sql
      end

      def connect
        Sequel.connect(:adapter  => sqlcfg.adapter,
                   :host     => sqlcfg.host?,
                   :user     => sqlcfg.user?,
                   :password => sqlcfg.password?,
                   :database => sqlcfg.database)
        rescue Sequel::AdapterNotFound => error
          raise OxidizedError, "SQL adapter gem not installed: " + error.message
      end

      def check_stats_table db
        db.create_table? (sqlcfg.table + '_stats').to_sym do
                primary_key [ :name, :group ],  :name=>'full_name'
                String      :name
                String      :group
                DateTime    :start
                DateTime    :end
                Float       :time
                String      :status
        end
      end
      
    end
  end
end
