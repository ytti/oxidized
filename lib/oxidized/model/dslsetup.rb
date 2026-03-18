module Oxidized
  class Model
    # Domain Specific Language for model setup
    module DSLSetup
      def prompt(regex = nil)
        @prompt = regex || @prompt
      end

      def comment(str = "# ")
        @comment = if block_given?
                     yield
                   elsif not @comment
                     str
                   else
                     @comment
                   end
      end

      def expect(regex, **args, &block)
        process_args_block(@expect, args, [regex, block])
      end

      def expects
        @expect
      end

      def cfg(*methods, **args, &block)
        [methods].flatten.each do |method|
          process_args_block(@cfg[method.to_s], args, block)
        end
      end

      def cfgs
        @cfg
      end

      # Define multiple inputs as a sequence of equivalent options
      # Example: use ssh or telnet, then scp or ftp:
      # [:ssh, [:scp, :ftp]]
      def inputs(list = nil)
        return @inputs if list.nil?

        validate_inputs(list)
        @inputs = list
      end

      # Returns the input sequence for the model as an array of arrays of input
      # classes, filtered and ordered according to the provided +input_classes+
      # (as specified in the oxidized configuration file).
      def input_sequence(input_classes)
        model_inputs = inputs || [
          @cfg.filter_map do |input, block_list|
            input.to_sym unless block_list.empty?
          end
        ]

        model_inputs.map do |sequence|
          sequence = [sequence] unless sequence.is_a? Array
          selected = input_classes.select { |input| sequence.include?(input.to_sym) }
          logger.error "Needs one of #{sequence.inspect} to be configured" if selected.empty?

          selected
        end
      end

      def metadata(position, value = nil, &block)
        return unless %i[top bottom].include? position

        if block_given?
          @metadata[position] = block
        else
          @metadata[position] = value
        end
      end

      def clean(what)
        case what
        when :escape_codes
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
      end

      private

      def validate_inputs(list)
        message = "inputs must be an array containing symbols or " \
                  "arrays of symbols"

        raise ArgumentError, message unless list.is_a? Array
        raise ArgumentError, message if list.empty?

        list.each do |group|
          case group
          when Symbol
            # Everything is fine
          when Array
            raise ArgumentError, message if group.empty?

            group.each do |input|
              raise ArgumentError, message unless input.is_a? Symbol
            end
          else
            raise ArgumentError, message
          end
        end
      end
    end
  end
end
