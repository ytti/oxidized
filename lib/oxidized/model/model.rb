require 'strscan'
require_relative 'outputs'

module Oxidized
  class Model
    include Oxidized::Config::Vars

    class << self
      def inherited(klass)
        if klass.superclass == Oxidized::Model
          klass.instance_variable_set '@cmd',     (Hash.new { |h, k| h[k] = [] })
          klass.instance_variable_set '@cfg',     (Hash.new { |h, k| h[k] = [] })
          klass.instance_variable_set '@procs',   (Hash.new { |h, k| h[k] = [] })
          klass.instance_variable_set '@expect',  []
          klass.instance_variable_set '@comment', nil
          klass.instance_variable_set '@prompt',  nil
        else # we're subclassing some existing model, take its variables
          instance_variables.each do |var|
            klass.instance_variable_set var, instance_variable_get(var)
          end
        end
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

      def prompt(regex = nil)
        @prompt = regex || @prompt
      end

      def cfg(*methods, **args, &block)
        [methods].flatten.each do |method|
          process_args_block(@cfg[method.to_s], args, block)
        end
      end

      def cfgs
        @cfg
      end

      def cmd(cmd_arg = nil, **args, &block)
        if cmd_arg.class == Symbol
          process_args_block(@cmd[cmd_arg], args, block)
        else
          process_args_block(@cmd[:cmd], args, [cmd_arg, block])
        end
        Oxidized.logger.debug "lib/oxidized/model/model.rb Added #{cmd_arg} to the commands list"
      end

      def cmds
        @cmd
      end

      def expect(regex, **args, &block)
        process_args_block(@expect, args, [regex, block])
      end

      def expects
        @expect
      end

      # calls the block at the end of the model, prepending the output of the
      # block to the output string
      #
      # @author Saku Ytti <saku@ytti.fi>
      # @since 0.0.39
      # @yield expects block which should return [String]
      # @return [void]
      def pre(**args, &block)
        process_args_block(@procs[:pre], args, block)
      end

      # calls the block at the end of the model, adding the output of the block
      # to the output string
      #
      # @author Saku Ytti <saku@ytti.fi>
      # @since 0.0.39
      # @yield expects block which should return [String]
      # @return [void]
      def post(**args, &block)
        process_args_block(@procs[:post], args, block)
      end

      # @author Saku Ytti <saku@ytti.fi>
      # @since 0.0.39
      # @return [Hash] hash proc procs :pre+:post to be prepended/postfixed to output
      attr_reader :procs

      private

      def process_args_block(target, args, block)
        if args[:clear]
          target.replace([block])
        else
          method = args[:prepend] ? :unshift : :push
          target.send(method, block)
        end
      end
    end

    attr_accessor :input, :node

    def cmd(string, &block)
      Oxidized.logger.debug "lib/oxidized/model/model.rb Executing #{string}"
      out = @input.cmd(string)
      return false unless out

      out = out.b unless Oxidized.config.input.utf8_encoded?
      self.class.cmds[:all].each do |all_block|
        out = instance_exec Oxidized::String.new(out), string, &all_block
      end
      if vars :remove_secret
        self.class.cmds[:secret].each do |all_block|
          out = instance_exec Oxidized::String.new(out), string, &all_block
        end
      end
      out = instance_exec Oxidized::String.new(out), &block if block
      process_cmd_output out, string
    end

    def output
      @input.output
    end

    def send(data)
      @input.send data
    end

    def expect(regex, &block)
      self.class.expect regex, &block
    end

    def cfg
      self.class.cfgs
    end

    def prompt
      self.class.prompt
    end

    def expects(data)
      self.class.expects.each do |re, cb|
        if data.match re
          data = cb.arity == 2 ? instance_exec([data, re], &cb) : instance_exec(data, &cb)
        end
      end
      data
    end

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

    def comment(str)
      data = ''
      str.each_line do |line|
        data << self.class.comment << line
      end
      data
    end

    def screenscrape
      @input.class.to_s.match(/Telnet/) || vars(:ssh_no_exec)
    end

    private

    def process_cmd_output(output, name)
      output = Oxidized::String.new(output) if output.is_a?(::String)
      output = Oxidized::String.new('') unless output.instance_of?(Oxidized::String)
      output.set_cmd(name)
      output
    end
  end
end
