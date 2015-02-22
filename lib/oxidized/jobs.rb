module Oxidized
  class Jobs < Array
    AVERAGE_DURATION = 5 # initially presume nodes take 5s to complete
    attr_accessor :interval, :max, :want
    def initialize max, interval, nodes
      @max       = max
      @interval  = interval
      @nodes     = nodes
      @durations = Array.new @nodes.size, AVERAGE_DURATION
      duration AVERAGE_DURATION
      super()
    end
    def duration last
      @durations.push(last).shift
      @duration = @durations.inject(:+).to_f / @nodes.size #rolling average
      new_count
    end
    def new_count
      @want = ((@nodes.size * @duration) / @interval).to_i
      @want = 1 if @want < 1
      @want = @nodes.size if @want > @nodes.size
      @want = @max if @want > @max
    end
    def add_job
      @want += 1
    end
  end
end
