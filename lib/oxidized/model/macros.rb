module Oxidized
  class Model
    module Macros
      using Refinements
      VERBS = %i[
        macro
        clean
      ].freeze

      VERBS.each do |verb|
        define_method(verb) do |name, *args, **kwargs, &block|
          send("#{verb}_#{name}", *args, **kwargs, &block)
        end
      end

      private

      def macro_enable(regex: /password/i, inputs: %i[telnet ssh], command: "enable")
        inputs = [inputs].flatten.map(&:to_sym)
        cfg(*inputs) do
          post_login do
            if vars(:enable) == true
              cmd command
            elsif vars(:enable)
              cmd command, regex
              cmd vars(:enable)
            end
          end
        end
      end

      def clean_escape_codes
        ansi_escape_regex = /
          \r?        # Optional carriage return at start
          \e         # ESC character - starts escape sequence
          (?:        # Non-capturing group for different sequence types:
            # Type 1: CSI (Control Sequence Introducer)
            \[       # Literal '[' - starts CSI sequence
            [0-?]*   # Parameter bytes: digits (0-9), semicolon, colon, etc.
            [ -\/]*  # Intermediate bytes: space through slash characters
            [@-~]    # Final byte: determines the actual command
          |          # OR
            # Type 2: Simple escape
            [=>]     # Single character commands after ESC
          )
          \r?        # Optional carriage return at end
        /x
        expect ansi_escape_regex do |data, re|
          data.gsub re, ''
        end
      end

      def clean_cut(head: 1, tail: 1)
        cmd :all do |cfg|
          cfg.cut_both(head, tail)
        end
      end
    end
  end
end
