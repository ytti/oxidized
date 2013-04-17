module Oxidized
  require 'ostruct'
  require 'yaml'
  class Config < OpenStruct
    require 'oxidized/config/defaults'
    # @param file [string] configuration file location
    def initialize file=File.join(Config::Root, 'config')
      super()
      @file = file.to_s
    end
    # load config from file or bootstrap with built-ins
    def load
      if File.exists? @file
        marshal_load YAML.load_file @file 
      else
        require 'oxidized/config/bootstrap'
      end
    end
    # save config to file
    def save
      File.write @file, YAML.dump(marshal_dump)
    end
  end
  CFG = Config.new
  CFG.load
  Log.file = CFG.log if CFG.log
  Log.level = Logger::INFO unless CFG.debug
end
