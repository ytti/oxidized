module Oxidized
  module Output
    # ruby's File class must be accessed with ::File to avoid name conflicts
    class File < Output
      require 'fileutils'

      attr_reader :commitref

      def initialize
        super
        @cfg = Oxidized.config.output.file
      end

      def setup
        return unless @cfg.empty?

        Oxidized.asetus.user.output.file.directory = ::File.join(Config::ROOT, 'configs')
        Oxidized.asetus.save :user
        raise NoConfig, "no output file config, edit #{Oxidized::Config.configfile}"
      end

      # node: node name (String)
      # outputs: Oxidized::Models::Outputs
      # opts: hash of node vars
      def store(node, outputs, opt = {})
        file = ::File.expand_path @cfg.directory
        file = ::File.join ::File.dirname(file), opt[:group] if opt[:group]
        FileUtils.mkdir_p file
        file = ::File.join file, node
        ::File.write(file, outputs.to_cfg)
        @commitref = file
      end

      def fetch(node, group)
        cfg_dir   = ::File.expand_path @cfg.directory
        node_name = node.name

        if group # group is explicitly defined by user
          cfg_dir = ::File.join ::File.dirname(cfg_dir), group
          ::File.read ::File.join(cfg_dir, node_name)
        elsif ::File.exist? ::File.join(cfg_dir, node_name) # node configuration file is stored on base directory
          ::File.read ::File.join(cfg_dir, node_name)
        else
          path = Dir.glob(::File.join(::File.dirname(cfg_dir), '**', node_name)).first # fetch node in all groups
          ::File.read path
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

      def self.node_path(node_name, group_name = nil)
        cfg_dir = ::File.expand_path Oxidized.config.output.file.directory

        if group_name
          ::File.join ::File.dirname(cfg_dir), group_name, node_name
        else
          ::File.join cfg_dir, node_name
        end
      end

      def self.clean_obsolete_nodes(active_nodes)
        cfg_dir = ::File.expand_path Oxidized.config.output.file.directory
        dir_base = ::File.dirname(cfg_dir)
        default_dir = ::File.basename(cfg_dir)

        keep_files = active_nodes.map { |n| node_path(n.name, n.group) }
        active_groups = active_nodes.map(&:group).compact.uniq

        [default_dir, *active_groups].each do |group|
          Dir.glob(::File.join(dir_base, group, "*")).each do |file|
            ::File.delete(file) if ::File.file?(file) && !keep_files.include?(file)
          end
        end
      end
    end
  end
end
