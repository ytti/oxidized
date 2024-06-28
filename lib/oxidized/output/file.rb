module Oxidized
  class OxidizedFile < Output
    require 'fileutils'

    attr_reader :commitref

    def initialize
      super
      @cfg = Oxidized.config.output.file
      Oxidized.logger.debug "Config #{@cfg.filename}"
    end

    def setup
      return unless @cfg.empty?

      Oxidized.asetus.user.output.file.directory = File.join(Config::ROOT, 'configs')
      Oxidized.asetus.save :user
      raise NoConfig, 'no output file config, edit ~/.config/oxidized/config'
    end

    def store(node, outputs, opt = {})
      filename = get_filename(node, opt)

      file = File.expand_path @cfg.directory
      file = File.join File.dirname(file), opt[:group] if opt[:group]
      FileUtils.mkdir_p file
      file = File.join file, filename
      File.write(file, outputs.to_cfg)
      @commitref = file
    end

    def fetch(node, group)
      cfg_dir   = File.expand_path @cfg.directory
      node_name = get_filename node.name, email: node.email, user: node.user, group: node.group, vars: node.vars

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

    def interpolate_format_string(format_string, vars)
      vars.each do |key, value|
        format_string = format_string.gsub("{{#{key}}}", value.to_s)
      end
      format_string
    end

    def flatten_variables(hash, parent_key = '', separator = '_')
      flat_hash = {}
      hash.each do |key, value|
        new_key = parent_key.empty? ? key.to_s : "#{parent_key}#{separator}#{key}"
        if value.is_a?(Hash)
          flat_hash.merge!(flatten_variables(value, new_key, separator))
        else
          flat_hash[new_key] = value
        end
      end
      flat_hash
    end

    def get_filename(node, opt)
      filename = node
      Oxidized.logger.debug "OPT Received: #{node} #{opt}"
      unless @cfg.filename.nil?
        Oxidized.logger.debug "Filename from config #{@cfg.filename}"
        flatten_ops = flatten_variables(opt)
        if @cfg.timeformat.nil || @cfg.timeformat.empty
          time = Time.now.strftime("%m%d%Y%H%M%S")
        else
          time = Time.now.strftime(@cfg.timeformat)
        end
        flatten_ops["time"] = time
        Oxidized.logger.debug "Flatten #{flatten_ops}"
        filename = interpolate_format_string(@cfg.filename, flatten_ops)
      end
      Oxidized.logger.debug "Filename #{filename}"
      filename
    end
  end
end
