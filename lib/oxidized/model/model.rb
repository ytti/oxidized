module Oxidized
  class Model
    class << self
      def inherited klass
        klass.instance_variable_set '@cmd',    Hash.new { |h,k| h[k] = [] }
        klass.instance_variable_set '@cfg',    Hash.new { |h,k| h[k] = [] }
        klass.instance_variable_set '@expect', []
        klass.const_set :CFG, CFG
        Oxidized.mgr.loader = { :class => klass }
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
    end

    attr_accessor :input

    def cmd string, &block
      out = @input.cmd string
      return false unless out
      self.class.cmds[:all].each do |all_block|
        out = instance_exec out, &all_block
      end
      out = instance_exec out, &block if block
      out
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
      data = ''
      self.class.cmds[:cmd].each do |command, block|
        out = cmd command, &block
        return false unless out
        data << out.to_s
      end
      data << main.to_s if respond_to? :main
      data
    end

    def comment _comment
      data = ''
      _comment.each_line do |line|
        data << self.class.comment << line
      end
      data
    end

  end
end
