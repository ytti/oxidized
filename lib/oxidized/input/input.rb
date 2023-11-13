module Oxidized
  class PromptUndetect < OxidizedError; end

  class Input
    include Oxidized::Config::Vars

    RESCUE_FAIL = {
      debug: [
        Errno::ECONNREFUSED
      ],
      warn:  [
        IOError,
        PromptUndetect,
        Timeout::Error,
        Errno::ECONNRESET,
        Errno::EHOSTUNREACH,
        Errno::ENETUNREACH,
        Errno::EPIPE,
        Errno::ETIMEDOUT
      ]
    }.freeze
  end
end
