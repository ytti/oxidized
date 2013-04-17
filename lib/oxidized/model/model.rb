module Oxidized
  class Model
    class << self
      def inherited klass
        klass.instance_variable_set '@cmd', []
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
        @cmd << [_cmd, block]
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
      self.class.cmds.each do |cmd, cb|
        out = @input.cmd cmd
        out = instance_exec out, &cb if cb
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
