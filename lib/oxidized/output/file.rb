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

  
  def fetch node, group
    cfg_dir = @cfg[:directory]
    if group != 0 # group is explicitly defined by user
      IO.readlines File.join(cfg_dir, group, node)
    else
      if File.exists?("#{cfg_dir}/#{node}") # node configuration file is stored on base directory
        IO.readlines File.join(cfg_dir, node)
      else
        Dir.foreach(cfg_dir) do |sub_dir|
          next if sub_dir == '.' or sub_dir == '..'
          if File.directory?("#{cfg_dir}/#{sub_dir}")
             files = Dir.entries("#{cfg_dir}/#{sub_dir}")
             files.each do |f|
                next if File.directory?("#{cfg_dir}/#{sub_dir}/#{f}") or f == '.' or f == '..'
                IO.readlines File.join(cfg_dir, sub_dir, f) if f == node # node configuration file found on sub directory
             end
          end
        end
      end
    end
  end
  
end
end
