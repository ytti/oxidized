module Oxidized
class SQL < Source
  begin
    require 'sequel'
  rescue LoadError
    raise LoadError, 'sequel not found: sudo gem install sequel'
  end

  def initialize
    super
    @cfg = CFG.source.sql
  end

  def setup
    if @cfg.empty?
      CFGS.user.source.sql.adapter   = 'sqlite'
      CFGS.user.source.sql.file      = File.join(Config::Root, 'sqlite.db')
      CFGS.user.source.sql.table     = 'devices'
      CFGS.user.source.sql.map.name  = 'name'
      CFGS.user.source.sql.map.model = 'rancid'
      CFGS.save :user
      raise NoConfig, 'no source sql config, edit ~/.config/oxidized/config'
    end
  end

  def load
    nodes = []
    db = case @cfg.adapter
    when 'sqlite'
      begin
        require 'sqlite3'
      rescue LoadError
        raise LoadError, 'sqlite3 not found: sudo apt install libsqlite3-dev; sudo gem install sqlite3'
      end
      Sequel.sqlite @cfg.file
    end
    db[@cfg.table.to_sym].each do |node|
      keys = {}
      @cfg.map.each { |key, sql_column| keys[key.to_sym] = node[sql_column.to_sym] }
      keys[:model] = map_model keys[:model] if keys.key? :model
      nodes << keys
    end
    nodes
  end

end
end
