require 'semantic_logger'

module Oxidized
  module Logger
    include SemanticLogger::Loggable

    def self.setup
      config = Oxidized.config
      FileUtils.mkdir_p(Config::LOG) unless File.directory?(Config::LOG)

      SemanticLogger.add_signal_handler

      if config.use_syslog?
        SemanticLogger.add_appender(appender: :syslog)
        logger.warn("The configuration 'use_syslog' is deprecated. " \
                    "Remove it and use 'logger' instead")
      elsif config.log?
        SemanticLogger.add_appender(file_name: File.expand_path(config.log))
        logger.warn("The configuration 'log' is deprecated. " \
                    "Remove it and use 'logger' instead")
      elsif config.logger?
        SemanticLogger.default_level = config.logger.level if config.logger.level?
        config.logger.appenders.each { |a| add_appender a } if config.logger.has_key?('appenders')
      end

      # No appenders configured
      SemanticLogger.add_appender(io: $stderr) if SemanticLogger.appenders.empty?

      return if %i[trace debug].include?(SemanticLogger.default_level)

      SemanticLogger.default_level = :debug if config.debug?
    end

    def self.add_appender(appender)
      case appender['type']
      when 'file'
        params = { file_name: File.expand_path(appender['file']) }
      when 'stderr'
        params = { io: $stderr }
      when 'stdout'
        params = { io: $stdout }
      when 'syslog'
        params = { appender: :syslog, application: "oxidized" }
      else
        raise InvalidConfig, "Unknown logger #{appender['type']}, edit #{Oxidized::Config.configfile}"
      end
      params[:level] = appender['level'] if appender.has_key?('level')
      SemanticLogger.add_appender(**params)
    end
  end
end
