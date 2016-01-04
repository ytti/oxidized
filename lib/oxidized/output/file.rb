module Oxidized
class OxidizedFile < Output
  require 'fileutils'

  attr_reader :commitref

  def initialize
    @cfg = Oxidized.config.output.file
  end

  def setup
    if @cfg.empty?
      Oxidized.asetus.user.output.file.directory = File.join(Config::Root, 'configs')
      Oxidized.asetus.save :user
      raise NoConfig, 'no output file config, edit ~/.config/oxidized/config'
    end
  end

  def store node, outputs, opt={}
    file = @cfg.directory
    if opt[:group]
      file = File.join File.dirname(file), opt[:group]
    end
    FileUtils.mkdir_p file
    file = File.join file, node
    open(file, 'w') { |fh| fh.write outputs.to_cfg }
    @commitref = file
  end

  def fetch node, group
    cfg_dir = @cfg.directory
    if group # group is explicitly defined by user
      IO.readlines File.join(cfg_dir, group, node)
    else
      if File.exists? File.join(cfg_dir, node) # node configuration file is stored on base directory
        IO.readlines File.join(cfg_dir, node)
      else
        path = Dir.glob File.join(cfg_dir, '**', node) # fetch node in all groups
        return nil if path[0].nil?
        open(path[0], 'r').readlines
      end
    end
  end

  def version node, group
    # not supported
    []
  end

  def get_version node, group, oid
    'not supported'
  end

end
end
