module Oxidized
  # This module contains all model classes for Inputs
  module Input
    require 'oxidized/error/promptundetected'

    # Represents the input handling for Oxidized.
    #
    # This class manages connections to network devices and handles input
    # processing, including error handling and recovery strategies.
    class Input
      include Oxidized::Config::Vars

      # A hash defining exceptions that may be raised during Input operations.
      RESCUE_FAIL = {
        debug: [
          Errno::ECONNREFUSED # Connection refused error
        ],
        warn:  [
          IOError,                    # I/O related errors
          Error::PromptUndetected,    # Prompt undetected error
          Timeout::Error,             # Timeout errors
          Errno::ECONNRESET,          # Connection reset error
          Errno::EHOSTUNREACH,        # Host unreachable error
          Errno::ENETUNREACH,         # Network unreachable error
          Errno::EPIPE,               # Broken pipe error
          Errno::ETIMEDOUT            # Operation timed out error
        ]
      }.freeze
    end
  end
end
