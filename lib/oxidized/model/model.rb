require 'strscan'
require_relative 'outputs'

module Oxidized
  class Model
    using Refinements

    include Oxidized::Config::Vars

    class << self
      def inherited(klass)
        super
        if klass.superclass == Oxidized::Model
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
        if cmd_arg.instance_of?(Symbol)
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

    attr_accessor :input, :node

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

    def output
      @input.output
    end

    def send(data)
      @input.send data
    end

    def expect(...)
      self.class.expect(...)
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

    def xmlcomment(str)
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

    def screenscrape
      @input.class.to_s.match(/Telnet/) || vars(:ssh_no_exec)
    end

    private

    def process_cmd_output(output, name)
      output = String.new('') unless output.instance_of?(String)
      output.process_cmd(name)
      output
    end
  end
end
