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
    file = File.expand_path @cfg.directory
    if opt[:group]
      file = File.join File.dirname(file), opt[:group]
    end
    FileUtils.mkdir_p file
    file = File.join file, node
    open(file, 'w') { |fh| fh.write outputs.to_cfg }
    @commitref = file
  end

  def fetch node, group
    cfg_dir   = File.expand_path @cfg.directory
    node_name = node.name

    if group # group is explicitly defined by user
      cfg_dir = File.join File.dirname(cfg_dir), group
      File.read File.join(cfg_dir, node_name)
    else
      if File.exists? File.join(cfg_dir, node_name) # node configuration file is stored on base directory
        File.read File.join(cfg_dir, node_name)
      else
        path = Dir.glob(File.join(File.dirname(cfg_dir), '**', node_name)).first # fetch node in all groups
        File.read path
      end
    end
  rescue Errno::ENOENT
    return nil
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
