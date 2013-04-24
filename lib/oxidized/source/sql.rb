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
    case @cfg[:adapter]
    when 'sqlite'
      require 'sqlite3'
      Sequel.sqlite @cfg[:file]
    end
    klass = Class.new(Sequel::Model @cfg[:table].to_sym)
    SQL.send :remove_const, :Nodes if SQL.const_defined? :Nodes
    SQL.const_set :Nodes, klass
    Nodes.each do |node|
      keys = {}
      @cfg[:map].each { |key, sql_column| keys[key] = node.send(sql_column.to_sym) }
      keys[:model] = map_model keys[:model] if keys.key? :model
      nodes << keys
    end
    nodes
  end

end
end
