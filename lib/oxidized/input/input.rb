module Oxidized
  class PromptUndetect < OxidizedError; end

  class Input
    include SemanticLogger::Loggable
    include Oxidized::Config::Vars

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
  end
end
