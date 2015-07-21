module Oxidized
  
  class Store
    require 'sqlite3'
    
    attr_reader :db, :stats_table
    
    def initialize
      @db = SQLite3::Database.new(CFG.database)
      @db.results_as_hash = true
    end
    
    def create_table_stats
      #check if the table stats exist
      check = @db.execute("SELECT * FROM sqlite_master WHERE name ='stats' and type='table'; ")
      #if not, create it
      if check.empty?
        @db.execute("create table 'stats' (node TEXT PRIMARY KEY, grp TEXT, start DATE, status TEXT, end DATE, time TEXT);")
      end
    end
    
    def update_stats node
      hash = {}
      hash[:start] = Time.now.utc
      hash[:status], hash[:config] = node.run
      hash[:end]             = Time.now.utc
      hash[:time]            = hash[:end] - hash[:start]
      
      create_table_stats
      
      node_exist = @db.execute("SELECT * FROM stats WHERE node = '#{node.name}' AND grp = '#{node.group}';")
      
      unless node_exist.empty?
        @db.execute("UPDATE stats SET start = '#{hash[:start]}', status = '#{hash[:status]}', end = '#{hash[:end]}', time = '#{hash[:time]}' WHERE node = '#{node.name}';")
      else
        @db.execute("INSERT INTO stats (node, grp, start, status, end, time) VALUES ('#{node.name}', '#{node.group}', '#{hash[:start]}', '#{hash[:status]}', '#{hash[:end]}', '#{hash[:time]}');")
      end
      get_node_stats node
      
      hash
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
   
  end
end