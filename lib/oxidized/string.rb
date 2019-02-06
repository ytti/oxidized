module Oxidized
  # Used in models, contains convenience methods
  class String < String
    attr_accessor :type, :cmd, :name

    # @return [Oxidized::String] copy of self with last line removed
    def cut_tail(lines = 1)
      Oxidized::String.new each_line.to_a[0..-1 - lines].join
    end

    # @return [Oxidized::String] copy of self with first line removed
    def cut_head(lines = 1)
      Oxidized::String.new each_line.to_a[lines..-1].join
    end

    # @return [Oxidized::String] copy of self with first and last lines removed
    def cut_both(head = 1, tail = 1)
      Oxidized::String.new each_line.to_a[head..-1 - tail].join
    end

    # sets @cmd and @name unless @name is already set
    def set_cmd(command)
      @cmd = command
      @name ||= @cmd.to_s.strip.gsub(/\s+/, '_') # what to do when command is proc? #to_s seems ghetto
    end

    def initialize(str = '')
      super
      return unless str.class == Oxidized::String

      @cmd  = str.cmd
      @name = str.name
      @type = str.type
    end
  end
end
