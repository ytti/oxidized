module Oxidized
  
  class Store
    require 'sqlite3'
    @@mutex = Mutex.new
    attr_reader :db, :stats_table
    
    def initialize
      @db = SQLite3::Database.new(CFG.database)
      @db.results_as_hash = true
    end
    
    def with_lock &block
      @@mutex.synchronize(&block)
    end
    
    def create_table_stats
      #check if the table stats exist
      check = @db.execute("SELECT * FROM sqlite_master WHERE name ='stats' and type='table';")
      #if not, create it
      if check.empty?
        @db.execute("create table 'stats' (node TEXT PRIMARY KEY, grp TEXT, start DATE, status TEXT, end DATE, time TEXT);")
      end
    end
    
    def update_stats job
      node = job.node  
      create_table_stats
      node_exist = @db.execute("SELECT * FROM stats WHERE node = '#{node.name}' AND grp = '#{node.group}';")
      
      unless node_exist.empty?
        with_lock do
          @db.execute("UPDATE stats SET start = '#{job.start}', status = '#{job.status}', end = '#{job.end}', time = '#{job.time}' WHERE node = '#{node.name}';")
        end
      else
        with_lock do
          @db.execute("INSERT INTO stats (node, grp, start, status, end, time) VALUES ('#{node.name}', '#{node.group}', '#{job.start}', '#{job.status}', '#{job.end}', '#{job.time}');")
        end
      end

    end
    
    #can be called with the node object, or the name of the node.
    def get_node_stats node
     unless node.respond_to?(:to_str)
       node = node.name
     end
     create_table_stats
     res = @db.execute("SELECT * FROM stats WHERE node = '#{node}';")
     unless res.empty?
       #create a hash to be used by node.last, we have to parse stats to right type before
       hash = {:start => Time.parse(res[0]["start"]), :status => res[0]["status"].to_sym, :end => Time.parse(res[0]["end"]), :time => res[0]["time"].to_f}
     else
       nil
     end     
    end
    
    def reset node_name
      with_lock do
        @db.execute("UPDATE stats SET end = '#{"000-01-01 00:00:00 UTC"}' WHERE node = '#{node_name}';")
      end
    end
    
    #Get stats for all nodes, in desired order, end ASC by default
    def get_nodes_stats order = "end ASC"
      create_table_stats
      res = @db.execute("SELECT * FROM stats ORDER BY #{order};")
    end
   
  end
end