module Oxidized
  class Model
    class << self
      def inherited klass
        klass.instance_variable_set '@cmd', Hash.new { |h,k| h[k] = [] }
        klass.instance_variable_set '@cfg', Hash.new { |h,k| h[k] = [] }
        Oxidized.mgr.loader = { :class => klass }
      end
      def comment _comment='# '
        return @comment if @comment
        @comment = block_given? ? yield : _comment
      end
      def cfg *methods, &block
        [methods].flatten.each do |method|
          @cfg[method.to_s] << block
        end
      end
      def prompt _prompt=nil
        @prompt or @prompt = _prompt
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
      def post_login &block
        @post_login or @post_login = block
      end
    end

    attr_accessor :input

    def cmd string
      out = @input.cmd string
      out = yield out if block_given?
      out
    end

    def  cfg
      self.class.cfgs
    end

    def prompt
      self.class.prompt
    end

    def cmds
      data = ''
      self.class.cmds[:cmd].each do |cmd, cmd_block|
        out = @input.cmd cmd
        self.class.cmds[:all].each do |all_block|
          out = instance_exec out, &all_block
        end
        out = instance_exec out, &cmd_block if cmd_block
        data << out.to_s
      end
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
