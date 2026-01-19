module Oxidized
  class Model
    # Domain Specific Language for model commands
    module DSLCommands
      # Store a command to be run against the device
      # cmd_arg can be:
      #  - a string (the command to be run)
      #  - a symbol:
      #    - :all    - run the block against each command output
      #    - :secret - run the block against each command output when
      #                vars :remove_secret is true
      #    - :significant_changes - use the block to remove unsignificant
      #                changes
      # Optional arguments (**args):
      # - clear: true
      #       replace all the stored blocks for this command (monkey patching)
      # - prepend: true
      #       prepend the block to the stored blocks for this command (monkey
      #       patching)
      # - if: lambda
      #       run the command only if the lambda evaluates to true
      # - input: symbol or array of symbols
      #       for the inputs this command is to run against (default - run
      #       every command)
      def cmd(cmd_arg = nil, **args, &block)
        if cmd_arg.instance_of?(Symbol)
          process_args_block(@cmd[cmd_arg], args, block)
        else
          return unless valid_cmd_args?(cmd_arg, args)

          # Always use an array for :input
          args[:input] = Array(args[:input]) if args.include?(:input)
          process_args_block(@cmd[:cmd], args,
                             { cmd: cmd_arg, args: args, block: block })
        end
        logger.debug "Added #{cmd_arg} to the commands list"
      end

      def cmds
        @cmd
      end

      # calls the block at the end of the model, prepending the output of the
      # block to the output string
      def pre(**args, &block)
        process_args_block(@procs[:pre], args, block)
      end

      # calls the block at the end of the model, adding the output of the block
      # to the output string
      def post(**args, &block)
        process_args_block(@procs[:post], args, block)
      end

      # @procs is a hash of procs (:pre+:post) to be prepended/postfixed to
      # output
      attr_reader :procs

      private

      def process_args_block(target, args, block)
        if args[:clear]
          if block.instance_of?(Array)
            target.reject! { |k, _| k == block[0] }
            target.push(block)
          elsif block.instance_of?(Hash)
            target.reject! { |item| item[:cmd] == block[:cmd] }
            target.push(block)
          else
            target.replace([block])
          end
        else
          method = args[:prepend] ? :unshift : :push
          target.send(method, block)
        end
      end

      def valid_cmd_args?(cmd_arg, args)
        if args.include?(:if) && !(args[:if].is_a?(Proc) && args[:if].lambda?)
          logger.error "cmd #{cmd_arg.dump}: if must be a lambda"
          return false
        end

        if args.include?(:input) && ![Symbol, Array].include?(args[:input].class)
          logger.error "cmd #{cmd_arg.dump}: input must be a symbol or an array of symbols"
          return false
        end

        true
      end
    end
  end
end
