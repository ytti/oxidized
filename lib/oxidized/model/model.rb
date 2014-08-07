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
        klass.const_set :CFG, CFG
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
      out = @input.cmd string
      return false unless out
      out = Oxidized::String.new out
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
      outputs = Outputs.new
      procs = self.class.procs
      procs[:pre].each do |pre_proc|
        outputs << instance_eval(&pre_proc)
      end
      self.class.cmds[:cmd].each do |command, block|
        out = cmd command, &block
        return false unless out
        outputs << out
      end
      procs[:post].each do |post_proc|
        outputs << instance_eval(&post_proc)
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

    private

    def process_cmd_output cmd, name
      if Hash === cmd
        cmd[:name] = name
        return cmd
      end
      {:output=>cmd, :type=>'cfg', :name=>name}
    end

  end
end
