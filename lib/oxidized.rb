require 'fileutils'
require 'refinements'

# Oxidized
#
# This module serves as the main namespace for the Oxidized application.
# It manages the connections to network devices and handles configuration
# backup and restoration processes.
module Oxidized
  # Directory for the Oxidized application, determined relative to the current file.
  Directory = File.expand_path(File.join(File.dirname(__FILE__), '../'))

  require 'oxidized/error/oxidizederror'
  require 'oxidized/version'
  require 'oxidized/config'
  require 'oxidized/config/vars'
  require 'oxidized/worker'
  require 'oxidized/nodes'
  require 'oxidized/manager'
  require 'oxidized/hook'
  require 'oxidized/signals'
  require 'oxidized/core'

  # @return [Asetus] the configuration object for Oxidized.
  def self.asetus
    @@asetus
  end

  # Sets the configuration object for Oxidized.
  #
  # @param val [Asetus] the configuration to set.
  def self.asetus=(val)
    @@asetus = val
  end

  # @return [Oxidized::Config] the configuration settings.
  def self.config
    asetus.cfg
  end

  # @return [Logger] the logger instance used by Oxidized.
  def self.logger
    @@logger
  end

  # Sets the logger instance for Oxidized.
  #
  # @param val [Logger] the logger instance to use.
  def self.logger=(val)
    @@logger = val
  end

  # Sets up the logging mechanism based on configuration.
  # If `use_syslog` is enabled, Syslog will be used; otherwise, it defaults to a standard logger.
  # It also sets the log level to `INFO` unless `debug` is enabled in the configuration.
  #
  # @raise [SystemCallError] if there's an issue creating the log directory.
  def self.setup_logger
    # @!visibility private
    # Create the log directory if it doesn't exist
    FileUtils.mkdir_p(Config::LOG) unless File.directory?(Config::LOG)
    # @!visibility private
    # Determine the logger type based on the configuration
    self.logger = if config.has_key?('use_syslog') && config.use_syslog
                    require 'syslog/logger'
                    Syslog::Logger.new('oxidized')
                  else
                    require 'logger'
                    # @!visibility private
                    # Use the specified log file or default to stderr
                    if config.has_key?('log')
                      Logger.new(File.expand_path(config.log))
                    else
                      Logger.new($stderr)
                    end
                  end
    # @!visibility private
    # Set logger level to INFO unless debug mode is enabled
    logger.level = Logger::INFO unless config.debug
  end
end
