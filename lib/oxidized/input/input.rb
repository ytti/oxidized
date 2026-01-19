require_relative 'cli'

module Oxidized
  class PromptUndetect < OxidizedError; end

  class Input
    include SemanticLogger::Loggable
    include Oxidized::Config::Vars
    include Oxidized::Input::CLI

    RESCUE_FAIL = {
      Errno::ECONNREFUSED => :debug,
      IOError             => :warn,
      PromptUndetect      => :warn,
      Timeout::Error      => :warn,
      Errno::ECONNRESET   => :warn,
      Errno::EHOSTUNREACH => :warn,
      Errno::ENETUNREACH  => :warn,
      Errno::EPIPE        => :warn,
      Errno::ETIMEDOUT    => :warn
    }.freeze

    # Returns a hash mapping exception classes to their log level
    def self.rescue_fail
      RESCUE_FAIL.dup
    end

    def self.config_name
      name.split('::').last.downcase
    end

    def self.to_sym
      config_name.to_sym
    end

    def config_name
      self.class.config_name
    end

    def to_sym
      self.class.to_sym
    end
  end
end
