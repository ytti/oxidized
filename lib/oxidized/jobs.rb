module Oxidized
  class Jobs < Array
    AVERAGE_DURATION  = 5   # initially presume nodes take 5s to complete
    MAX_INTER_JOB_GAP = 300 # add job if more than X from last job started
    attr_accessor :interval, :max, :want

    def initialize(max, interval, nodes)
      @max       = max
      # Set interval to 1 if interval is 0 (=disabled) so we don't break
      # the 'ceil' function
      @interval  = interval.zero? ? 1 : interval
      @nodes     = nodes
      @last      = Time.now.utc
      @durations = Array.new @nodes.size, AVERAGE_DURATION
      duration AVERAGE_DURATION
      super()
    end

    def push(arg)
      @last = Time.now.utc
      super
    end

    def duration(last)
      if @durations.size > @nodes.size
        @durations.slice! @nodes.size...@durations.size
      elsif @durations.size < @nodes.size
        @durations.fill AVERAGE_DURATION, @durations.size...@nodes.size
      end
      @durations.push(last).shift
      @duration = @durations.inject(:+).to_f / @nodes.size # rolling average
      new_count
    end

    def new_count
      @want = ((@nodes.size * @duration) / @interval).ceil
      @want = 1 if @want < 1
      @want = @nodes.size if @want > @nodes.size
      @want = @max if @want > @max
    end

    def work
      # if   a) we want less or same amount of threads as we now running
      # and  b) we want less threads running than the total amount of nodes
      # and  c) there is more than MAX_INTER_JOB_GAP since last one was started
      # then we want one more thread (rationale is to fix hanging thread causing HOLB)
      return unless @want <= size && @want < @nodes.size

      @want += 1 if (Time.now.utc - @last) > MAX_INTER_JOB_GAP
    end
  end
end
