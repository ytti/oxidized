require 'strscan'
require_relative 'outputs'

module Oxidized
  class Model
    include Oxidized::Config::Vars

    class << self
      def inherited klass
        klass.instance_variable_set '@cmd',   Hash.new { |h,k| h[k] = [] }
        klass.instance_variable_set '@cfg',   Hash.new { |h,k| h[k] = [] }
        klass.instance_variable_set '@procs', Hash.new { |h,k| h[k] = [] }
        klass.instance_variable_set '@expect', []
        klass.instance_variable_set '@comment', nil
        klass.instance_variable_set '@prompt', nil
      end
      def comment _comment='# '
        return @comment if @comment
        @comment = block_given? ? yield : _comment
      end
      def prompt _prompt=nil
        @prompt or @prompt = _prompt
      end
      def cfg *methods, &block
        [methods].flatten.each do |method|
          @cfg[method.to_s] << block
        end
      end
      def cfgs
        @cfg
      end
      def cmd _cmd=nil, &block
        if _cmd.class == Symbol
          @cmd[_cmd] << block
        else
          @cmd[:cmd] << [_cmd, block]
        end
        Oxidized.logger.debug "lib/oxidized/model/model.rb Added #{_cmd} to the commands list"
      end
      def cmds
        @cmd
      end
      def expect re, &block
        @expect << [re, block]
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
      def pre &block
        @procs[:pre] << block
      end

      # calls the block at the end of the model, adding the output of the block
      # to the output string
      #
      # @author Saku Ytti <saku@ytti.fi>
      # @since 0.0.39
      # @yield expects block which should return [String]
      # @return [void]
      def post &block
        @procs[:post] << block
      end

      # @author Saku Ytti <saku@ytti.fi>
      # @since 0.0.39
      # @return [Hash] hash proc procs :pre+:post to be prepended/postfixed to output
      def procs
        @procs
      end
    end

    attr_accessor :input, :node

    def cmd string, &block
      Oxidized.logger.debug "lib/oxidized/model/model.rb Executing #{string}"
      out = @input.cmd(string)
      return false unless out
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

    def send data
      @input.send data
    end

    def expect re, &block
      self.class.expect re, &block
    end

    def cfg
      self.class.cfgs
    end

    def prompt
      self.class.prompt
    end

    def expects data
      self.class.expects.each do |re, cb|
        if data.match re
          if cb.arity == 2
            data = instance_exec [data, re], &cb
          else
            data = instance_exec data, &cb
          end
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

    def comment _comment
      data = ''
      _comment.each_line do |line|
        data << self.class.comment << line
      end
      data
    end

    def screenscrape
      @input.class.to_s.match(/Telnet/) || vars(:ssh_no_exec)
    end

    private

    def process_cmd_output output, name
      output = Oxidized::String.new output if ::String === output
      output = Oxidized::String.new '' unless Oxidized::String === output
      output.set_cmd(name)
      output
    end

  end
end
