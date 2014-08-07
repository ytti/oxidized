module Oxidized
  # Used in models, contains convenience methods
  class String < String
    attr_accessor :type, :cmd

    # @return [Oxidized::String] copy of self with last line removed
    def cut_tail
      Oxidized::String.new each_line.to_a[0..-2].join
    end

    # @return [Oxidized::String] copy of self with first line removed
    def cut_head
      Oxidized::String.new each_line.to_a[1..-1].join
    end

    # @return clean/filename version of cmd
    def name
      cmd.strip.gsub(/\s+/, '_')
    end

    private

    def initialize arg
      super
      @type = 'cfg'
      @cmd  = 'n/a'
    end
  end
end
