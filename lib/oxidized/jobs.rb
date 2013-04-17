module Oxidized
  class Jobs < Array
    attr_accessor :interval, :duration, :max, :want
    def initialize max, interval, nodes
      @max       = max
      #@interval  = interval * 60
      @interval  = interval
      @nodes     = nodes
      @duration  = 4
      new_count
      super()
    end
    def duration last
      @duration = (@duration + last) / 2
      new_count
    end
    def new_count
      @want = ((@nodes.size * @duration) / @interval).to_i
      @want = 1 if @want < 1
      @want = @nodes.size if @want > @nodes.size
      @want = @max if @want > @max
    end
  end
end
