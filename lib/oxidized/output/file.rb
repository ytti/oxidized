module Oxidized
  class OxidizedFile < Output
    require 'fileutils'

    attr_reader :commitref

    def initialize
      @cfg = Oxidized.config.output.file
    end

    def setup
      return unless @cfg.empty?

      Oxidized.asetus.user.output.file.directory = File.join(Config::Root, 'configs')
      Oxidized.asetus.save :user
      raise NoConfig, 'no output file config, edit ~/.config/oxidized/config'
    end

    def store(node, outputs, opt = {})
      file = File.expand_path @cfg.directory
      file = File.join File.dirname(file), opt[:group] if opt[:group]
      FileUtils.mkdir_p file
      file = File.join file, node
      File.open(file, 'w') { |fh| fh.write outputs.to_cfg }
      @commitref = file
    end

    def fetch(node, group)
      cfg_dir   = File.expand_path @cfg.directory
      node_name = node.name

      if group # group is explicitly defined by user
        cfg_dir = File.join File.dirname(cfg_dir), group
        File.read File.join(cfg_dir, node_name)
      elsif File.exist? File.join(cfg_dir, node_name) # node configuration file is stored on base directory
        File.read File.join(cfg_dir, node_name)
      else
        path = Dir.glob(File.join(File.dirname(cfg_dir), '**', node_name)).first # fetch node in all groups
        File.read path
      end
    rescue Errno::ENOENT
      nil
    end

    def version(_node, _group)
      # not supported
      []
    end

    def get_version(_node, _group, _oid)
      'not supported'
    end
  end
end
