module Oxidized
  # Hides values of sensitive keys (passwords, tokens, ...) in logs and outputs
  module Redact
    SENSITIVE_NAME_RE = /(password|passphrase|secret|token|enable|
                          (private|api|access)_?key|
                          community|credential|auth
                        )/ix
    REDACTED = '[REDACTED]'.freeze

    def self.sensitive?(name)
      name.to_s.match?(SENSITIVE_NAME_RE)
    end

    def self.value(name, value)
      sensitive?(name) ? REDACTED : value
    end
  end
end
