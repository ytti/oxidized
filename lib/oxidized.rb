require 'fileutils'

module Oxidized
  class OxidizedError < StandardError; end

  Directory = File.expand_path(File.join(File.dirname(__FILE__), '../'))

  require 'oxidized/version'
  require 'oxidized/string'
  require 'oxidized/config'
  require 'oxidized/config/vars'
  require 'oxidized/worker'
  require 'oxidized/nodes'
  require 'oxidized/manager'
  require 'oxidized/hook'
  require 'oxidized/core'

  def self.asetus
    @@asetus
  end

  def self.asetus=(val)
    @@asetus = val
  end

  def self.config
    asetus.cfg
  end

  def self.logger
    @@logger
  end

  def self.logger=(val)
    @@logger = val
  end

  def self.setup_logger
    FileUtils.mkdir_p(Config::Log) unless File.directory?(Config::Log)
    self.logger = if config.has_key?('use_syslog') && config.use_syslog
                    require 'syslog/logger'
                    Syslog::Logger.new('oxidized')
                  else
                    require 'logger'
                    if config.has_key?('log')
                      Logger.new(File.expand_path(config.log))
                    else
                      Logger.new(STDERR)
                    end
                  end
    logger.level = Logger::INFO unless config.debug
  end
end
