require 'fileutils'
require 'refinements'

module Oxidized
  class OxidizedError < StandardError; end

  Directory = File.expand_path(File.join(File.dirname(__FILE__), '../'))

  require 'oxidized/version'
  require 'oxidized/config'
  require 'oxidized/config/vars'
  require 'oxidized/worker'
  require 'oxidized/nodes'
  require 'oxidized/manager'
  require 'oxidized/hook'
  require 'oxidized/signals'
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
    FileUtils.mkdir_p(Config::LOG) unless File.directory?(Config::LOG)
    self.logger = if config.has_key?('use_syslog') && config.use_syslog
                    require 'syslog/logger'
                    Syslog::Logger.new('oxidized')
                  else
                    require 'logger'
                    if config.has_key?('log')
                      Logger.new(File.expand_path(config.log))
                    else
                      Logger.new($stderr)
                    end
                  end
    logger.level = Logger::INFO unless config.debug
  end
end
