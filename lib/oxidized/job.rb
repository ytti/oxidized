module Oxidized
  class Job < Thread
    attr_reader :start, :end, :status, :time, :node, :config
    def initialize node
      @node         = node
      @start        = Time.now.utc
      super do |node|
        @status, @config = node.run 
        @end             = Time.now.utc
        @time            = @end - @start
      end
    end
  end
end
