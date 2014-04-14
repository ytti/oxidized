module Oxidized
class CSV < Source
  def initialize
    @cfg = CFG.source.csv
    super
  end

  def setup
    if @cfg.empty?
      CFGS.user.source.csv.file      = File.join(Config::Root, 'router.db')
      CFGS.user.source.csv.delimiter = /:/
      CFGS.user.source.csv.map.name  = 0
      CFGS.user.source.csv.map.model = 1
      CFGS.save :user
      raise NoConfig, 'no source csv config, edit ~/.config/oxidized/config'
    end
  end

  def load
    nodes = []
    open(@cfg.file).each_line do |line|
      data  = line.chomp.split @cfg.delimiter
      keys = {}
      @cfg.map.each do |key, position|
        keys[key.to_sym] = data[position]
      end
      keys[:model] = map_model keys[:model] if keys.key? :model
      nodes << keys
    end
    nodes
  end

end
end
