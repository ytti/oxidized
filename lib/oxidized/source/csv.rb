module Oxidized
class CSV < Source
  def initialize
    @cfg = CFG.source[:csv]
    super
  end

  def setup
    if not @cfg
      CFG.source[:csv] = {
        :file      => File.join(Config::Root, 'router.db'),
        :delimiter => /:/,
        :map       => {
          :name  => 0,
          :model => 1,
        }
      }
      CFG.save
    end
  end

  def load
    nodes = []
    open(@cfg[:file]).each_line do |line|
      data  = line.chomp.split @cfg[:delimiter]
      keys = {}
      @cfg[:map].each do |key, position|
        keys[key] = data[position]
      end
      keys[:model] = map_model keys[:model] if keys.key? :model
      nodes << keys
    end
    nodes
  end

end
end
