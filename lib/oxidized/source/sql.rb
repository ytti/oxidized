module Oxidized
class SQL < Source
  begin
    require 'sequel'
  rescue LoadError
    raise OxidizedError, 'sequel not found: sudo gem install sequel'
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

  def connect
    #begin
      #require @cfg.adapter
    #rescue LoadError
      #raise OxidizedError, "@{cfg.adapter} not found: install gem"
    #end
    Sequel.connect(:adapter  => @cfg.adapter,
                   :host     => @cfg.host,
                   :user     => @cfg.user,
                   :password => @cfg.password,
                   :database => @cfg.database)
  end

  def load
    nodes = []
    db = connect
    if @cfg.query?
      query = db[@cfg.table.to_sym].with_sql(@cfg.query)
    else
      query = db[@cfg.table.to_sym]
    end
    query.each do |node|
      # map node parameters
      keys = {}
      @cfg.map.each { |key, sql_column| keys[key.to_sym] = node[sql_column.to_sym] }
      keys[:model] = map_model keys[:model] if keys.key? :model

      # map node specific vars
      vars = {}
      @cfg.vars_map.each { |key, sql_column| vars[key.to_sym] = node[sql_column.to_sym] }
      keys[:vars] = vars unless vars.empty?

      nodes << keys
    end
    nodes
  end

end
end
