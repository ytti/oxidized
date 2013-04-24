module Oxidized
class SQL < Source
  require 'sequel'

  def initialize
    super
    @cfg = CFG.source[:sql]
  end

  def setup
    if not @cfg
      CFG.source[:sql] = {
        :adapter => 'sqlite',
        :file    => File.join(Config::Root, 'sqlite.db'),
        :table   => 'devices',
        :map     => {
          :name      => 'name',
          :model     => 'rancid',
        }
      }
    end
    CFG.save
  end

  def load
    nodes = []
    db = case @cfg[:adapter]
    when 'sqlite'
      require 'sqlite3'
      Sequel.sqlite @cfg[:file]
    end
    db[@cfg[:table].to_sym].each do |node|
      keys = {}
      @cfg[:map].each { |key, sql_column| keys[key] = node[sql_column.to_sym] }
      keys[:model] = map_model keys[:model] if keys.key? :model
      nodes << keys
    end
    nodes
  end

end
end
