module Oxidized
class OxFile < Output
  require 'fileutils'

  def initialize
    @cfg = CFG.output[:file]
  end

  def setup
    if not @cfg
      CFG.output[:file] = {
        :directory => File.join(Config::Root, 'configs')
      }
      CFG.save
    end
  end

  def store node, data, opt={}
    file = @cfg[:directory]
    if opt[:group]
      file = File.join File.dirname(file), opt[:group]
    end
    FileUtils.mkdir_p file
    file = File.join file, node
    open(file, 'w') { |fh| fh.write data }
  end

  def fetch node
    IO.readlines File.join(@cfg[:directory], node)
  end

end
end
