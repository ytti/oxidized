module Refinements
  # Use the 'refine' keyword to define refinements for the String class
  refine String do
    attr_accessor :type, :cmd, :name

    # @return [String] copy of self with last line removed
    def cut_tail(lines = 1)
      return "" if length.zero?

      each_line.to_a[0..(-1 - lines)].join
    end

    # @return [String] copy of self with first line removed
    def cut_head(lines = 1)
      return "" if length.zero?

      each_line.to_a[lines..-1].join
    end

    # @return [String] copy of self with first and last lines removed
    def cut_both(head = 1, tail = 1)
      return "" if length.zero?

      each_line.to_a[head..(-1 - tail)].join
    end

    # sets @cmd and @name unless @name is already set
    def process_cmd(command)
      @cmd = command
      @name ||= @cmd.to_s.strip.gsub(/\s+/, '_') # what to do when command is proc? #to_s seems ghetto
    end

    # Initializes the String instance variables from another String instance
    # when the given str is an instance of String with Oxidized refinements applied
    def init_from_string(str = '')
      raise TypeError unless str.instance_of?(String)

      @cmd  = str.instance_variable_get(:@cmd)
      @name = str.instance_variable_get(:@name)
      @type = str.instance_variable_get(:@type)
    end
  end
end
