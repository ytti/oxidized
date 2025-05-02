require 'semantic_logger'
require 'fileutils'
require 'refinements'

module Oxidized
  class OxidizedError < StandardError; end
  include SemanticLogger::Loggable

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

  def self.setup_logger
    FileUtils.mkdir_p(Config::LOG) unless File.directory?(Config::LOG)

    # Reset the configuration of SemanticLogger as setup_logger can be called
    # many times, especialy from the specs.
    SemanticLogger.clear_appenders!
    SemanticLogger.default_level = :info
    self.logger = nil

    if config.has_key?('use_syslog') && config.use_syslog
      SemanticLogger.add_appender(appender: :syslog)
      logger.warn("The configuration 'use_syslog' is deprecated." \
                  "Remove it and use 'logger' instead")

    elsif config.has_key?('log')
      SemanticLogger.add_appender(file_name: File.expand_path(config.log))
      logger.warn("The configuration 'log' is deprecated." \
                  "Remove it and use 'logger' instead")

    elsif config.has_key?('logger')
      SemanticLogger.default_level = config.logger.level if config.logger.level?
      config.logger.appenders.each { |a| setup_appender a } if config.logger.has_key?('appenders')

    else # Nothing specified
      SemanticLogger.add_appender(io: $stderr)
    end

    # config.logger specified without appenders
    SemanticLogger.add_appender(io: $stderr) if SemanticLogger.appenders.empty?

    return if %i[trace debug].include?(SemanticLogger.default_level)

    SemanticLogger.default_level = :debug if config.debug?
  end

  def self.setup_appender(appender)
    case appender['type']
    when 'file'
      params = { file_name: File.expand_path(appender['file']) }
    when 'stderr'
      params = { io: $stderr }
    when 'syslog'
      params = { appender: :syslog }
    else
      raise InvalidConfig, "Unknown logger #{appender['type']}, edit #{Oxidized::Config.configfile}"
    end
    params[:level] = appender['level'] if appender.has_key?('level')
    SemanticLogger.add_appender(**params)
  end
end
