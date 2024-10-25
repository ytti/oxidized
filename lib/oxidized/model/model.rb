require 'strscan'
require_relative 'outputs'

module Oxidized
  # This module contains all model classes for device configurations.
  module Models
    # Represents a model for interacting with network devices.
    #
    # This class provides a framework for defining commands, processing output,
    # and handling interactions with nodes. It includes support for pre- and
    # post-processing output and command execution.
    class Model
      using Refinements

      include Oxidized::Config::Vars

      class << self
        # Called when a subclass of Model is created.
        #
        # @param klass [Class] The subclass being defined.
        def inherited(klass)
          super
          if klass.superclass == Oxidized::Models::Model
            klass.instance_variable_set '@cmd',     (Hash.new { |h, k| h[k] = [] })
            klass.instance_variable_set '@cfg',     (Hash.new { |h, k| h[k] = [] })
            klass.instance_variable_set '@procs',   (Hash.new { |h, k| h[k] = [] })
            klass.instance_variable_set '@expect',  []
            klass.instance_variable_set '@comment', nil
            klass.instance_variable_set '@prompt',  nil
          else # we're subclassing some existing model, take its variables
            instance_variables.each do |var|
              iv = instance_variable_get(var)
              klass.instance_variable_set var, iv.dup
              @cmd[:cmd] = iv[:cmd].dup if var.to_s == "@cmd"
            end
          end
        end

        # Sets the comment prefix for commands.
        #
        # @param str [String] The comment string.
        # @return [String] The comment string.
        def comment(str = "# ")
          @comment = if block_given?
                       yield
                     elsif not @comment
                       str
                     else
                       @comment
                     end
        end

        # Sets the prompt regex for command output.
        #
        # @param regex [Regexp, nil] The prompt regex.
        # @return [Regexp, nil] The current prompt regex.
        def prompt(regex = nil)
          @prompt = regex || @prompt
        end

        # Defines configuration methods for the model.
        #
        # @param methods [Symbol, Array<Symbol>] Methods to define.
        # @param args [Hash] Additional arguments.
        # @yield [block] Block to process.
        def cfg(*methods, **args, &block)
          [methods].flatten.each do |method|
            process_args_block(@cfg[method.to_s], args, block)
          end
        end

        # Returns the configuration methods.
        #
        # @return [Hash] The configuration methods.
        def cfgs
          @cfg
        end

        # Defines a command for the model.
        #
        # @param cmd_arg [Symbol, String] The command to define.
        # @param args [Hash] Additional arguments.
        # @yield [block] Block to process.
        def cmd(cmd_arg = nil, **args, &block)
          if cmd_arg.instance_of?(Symbol)
            process_args_block(@cmd[cmd_arg], args, block)
          else
            process_args_block(@cmd[:cmd], args, [cmd_arg, block])
          end
          Oxidized.logger.debug "lib/oxidized/model/model.rb Added #{cmd_arg} to the commands list"
        end

        # Returns the defined commands.
        #
        # @return [Hash] The defined commands.
        def cmds
          @cmd
        end

        # Defines an expectation for command output.
        #
        # @param regex [Regexp] The regex to match output.
        # @param args [Hash] Additional arguments.
        # @yield [block] Block to process.
        def expect(regex, **args, &block)
          process_args_block(@expect, args, [regex, block])
        end

        # Returns the defined expectations.
        #
        # @return [Array] The defined expectations.
        def expects
          @expect
        end

        # Calls the block at the end of the model, prepending the output of the
        # block to the output string
        #
        # @author Saku Ytti <saku@ytti.fi>
        # @since 0.0.39
        # @yield expects block which should return [String]
        # @return [void]
        def pre(**args, &block)
          process_args_block(@procs[:pre], args, block)
        end

        # Calls the block at the end of the model, adding the output of the block
        # to the output string
        #
        # @author Saku Ytti <saku@ytti.fi>
        # @since 0.0.39
        # @yield expects block which should return [String]
        # @return [void]
        def post(**args, &block)
          process_args_block(@procs[:post], args, block)
        end

        # Returns the registered pre- and post-processing blocks.
        # @author Saku Ytti <saku@ytti.fi>
        # @since 0.0.39
        # @return [Hash] hash proc procs :pre+:post to be prepended/postfixed to output
        attr_reader :procs

        private

        # Processes arguments and a block for commands and expectations.
        #
        # @param target [Array] The target array to modify.
        # @param args [Hash] Additional arguments.
        # @param block [Proc, Array] The block to process.
        def process_args_block(target, args, block)
          if args[:clear]
            if block.instance_of?(Array)
              target.reject! { |k, _| k == block[0] }
              target.push(block)
            else
              target.replace([block])
            end
          else
            method = args[:prepend] ? :unshift : :push
            target.send(method, block)
          end
        end
      end

      # @!attribute [rw] input
      #   @return [Input] The input object used for command execution.
      attr_accessor :input

      # @!attribute [rw] node
      #   @return [Node] The node associated with this model.
      attr_accessor :node

      # Executes a command and processes its output.
      #
      # @param string [String] The command to execute.
      # @yield [block] Block to process the output.
      # @return [String, false] The command output or false on failure.
      def cmd(string, &block)
        Oxidized.logger.debug "lib/oxidized/model/model.rb Executing #{string}"
        out = @input.cmd(string)
        return false unless out

        out = out.b unless Oxidized.config.input.utf8_encoded?
        self.class.cmds[:all].each do |all_block|
          out = instance_exec out, string, &all_block
        end
        if vars :remove_secret
          self.class.cmds[:secret].each do |all_block|
            out = instance_exec out, string, &all_block
          end
        end
        out = instance_exec out, &block if block
        process_cmd_output out, string
      end

      # Returns the output object associated with the model.
      #
      # @return [Output] The output object.
      def output
        @input.output
      end

      # Sends data to the input object.
      #
      # @param data [String] The data to send.
      # @return [void]
      def send(data)
        @input.send data
      end

      # Defines an expectation for command output.
      #
      # @param args [Array] Arguments for the expectation.
      # @return [void]
      def expect*args
        self.class.expect(*args)
      end

      # Returns the configuration methods.
      #
      # @return [Hash] The configuration methods.
      def cfg
        self.class.cfgs
      end

      # Returns the prompt regex.
      #
      # @return [Regexp, nil] The current prompt regex.
      def prompt
        self.class.prompt
      end

      # Processes data against defined expectations.
      #
      # @param data [String] The data to process.
      # @return [String] The processed data.
      def expects(data)
        self.class.expects.each do |re, cb|
          if data.match re
            data = cb.arity == 2 ? instance_exec([data, re], &cb) : instance_exec(data, &cb)
          end
        end
        data
      end

      # Collects outputs from commands executed by the model.
      #
      # @return [Outputs] The collected outputs.
      def get
        Oxidized.logger.debug 'lib/oxidized/model/model.rb Collecting commands\' outputs'
        outputs = Outputs.new
        procs = self.class.procs
        self.class.cmds[:cmd].each do |command, block|
          out = cmd command, &block
          return false unless out

          outputs << out
        end
        procs[:pre].each do |pre_proc|
          outputs.unshift process_cmd_output(instance_eval(&pre_proc), '')
        end
        procs[:post].each do |post_proc|
          outputs << process_cmd_output(instance_eval(&post_proc), '')
        end
        outputs
      end

      # Formats a comment string for output.
      #
      # @param str [String] The comment string.
      # @return [String] The formatted comment.
      def comment(str)
        data = ''
        str.each_line do |line|
          data << self.class.comment << line
        end
        data
      end

      # Formats an XML comment string for output.
      #
      # @param str [String] The comment string.
      # @return [String] The formatted XML comment.
      def xmlcomment(str)
        # @!visibility private
        # XML Comments start with <!-- and end with -->
        #
        # Because it's illegal for the first or last characters of a comment
        # to be a -, i.e. <!--- or ---> are illegal, and also to improve
        # readability, we add extra spaces after and before the beginning
        # and end of comment markers.
        #
        # Also, XML Comments must not contain --. So we put a space between
        # any double hyphens, by replacing any - that is followed by another -
        # with '- '
        data = ''
        str.each_line do |_line|
          data << '<!-- ' << str.gsub(/-(?=-)/, '- ').chomp << " -->\n"
        end
        data
      end

      # Checks if screen scraping is enabled.
      #
      # @return [Boolean] True if screen scraping is enabled.
      def screenscrape
        @input.class.to_s.match(/Telnet/) || vars(:ssh_no_exec)
      end

      private

      # Processes command output and prepares it for use.
      #
      # @param output [String] The output string.
      # @param name [String] The command name.
      # @return [String] The processed output.
      def process_cmd_output(output, name)
        output = String.new('') unless output.instance_of?(String)
        output.process_cmd(name)
        output
      end
    end
  end
end
