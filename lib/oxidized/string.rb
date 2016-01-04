module Oxidized
  # Used in models, contains convenience methods
  class String < String
    attr_accessor :type, :cmd, :name

    # @return [Oxidized::String] copy of self with last line removed
    def cut_tail
      Oxidized::String.new each_line.to_a[0..-2].join
    end

    # @return [Oxidized::String] copy of self with first line removed
    def cut_head
      Oxidized::String.new each_line.to_a[1..-1].join
    end

    # sets @cmd and @name unless @name is already set
    def set_cmd command
      @cmd  = command
      @name ||= @cmd.strip.gsub(/\s+/, '_')
    end

    def initialize str=''
      super
      if str.class == Oxidized::String
        @cmd  = str.cmd
        @name = str.name
        @type = str.type
      end
    end

  end
end
