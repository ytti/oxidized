module Oxidized
  # The Jobs class manages the queue of configuration fetch jobs.
  # It extends from `Array` to manage the collection of jobs.
  class Jobs < Array
    # Average duration (in seconds) a node takes to complete a job.
    AVERAGE_DURATION  = 5 # initially presume nodes take 5s to complete
    # Maximum time gap (in seconds) allowed between the start of two jobs.
    MAX_INTER_JOB_GAP = 300 # add job if more than X from last job started

    # @!attribute [rw] interval
    #   @return [Integer] the interval between jobs
    attr_accessor :interval

    # @!attribute [rw] max
    #   @return [Integer] the maximum number of jobs allowed to run simultaneously
    attr_accessor :max

    # @!attribute [rw] want
    #   @return [Integer] the desired number of concurrent jobs
    attr_accessor :want

    # Initializes a new Jobs instance.
    #
    # @param max [Integer] the maximum number of concurrent jobs.
    # @param use_max_threads [Boolean] whether to always use the maximum number of threads.
    # @param interval [Integer] the interval in seconds between job executions.
    # @param nodes [Array<Node>] the list of nodes for which jobs will be created.
    def initialize(max, use_max_threads, interval, nodes)
      @max = max
      @use_max_threads = use_max_threads
      # @!visibility private
      # Set interval to 1 if interval is 0 (=disabled) so we don't break
      # the 'ceil' function
      @interval = interval.zero? ? 1 : interval
      @nodes = nodes
      @last = Time.now.utc
      @durations = Array.new @nodes.size, AVERAGE_DURATION
      duration AVERAGE_DURATION
      super()
    end

    # Adds a job to the queue and updates the last job start time.
    #
    # @param arg [Object] the job to be added.
    def push(arg)
      @last = Time.now.utc
      super
    end

    # Updates the rolling average duration of jobs and recalculates the desired number of concurrent jobs.
    #
    # @param last [Float] the duration of the last completed job.
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

    # Recalculates the desired number of concurrent jobs based on the job durations, interval, and max threads.
    def new_count
      @want = if @use_max_threads
                @max
              else
                ((@nodes.size * @duration) / @interval).ceil
              end
      @want = 1 if @want < 1
      @want = @nodes.size if @want > @nodes.size
      @want = @max if @want > @max
    end

    # Safely increments the number of concurrent jobs if allowed.
    def increment
      # @!visibility private
      # Increments the job count if safe to do so, which means:
      # a) less threads running than the total amount of nodes
      # b) we want less than the max specified number of threads

      @want = [(@want + 1), @nodes.size, @max].min
    end

    # Manages job execution and decides whether to add new jobs based on the time since the last job.
    def work
      # @!visibility private
      # if   a) we want less or same amount of threads as we now running
      # and  b) we want less threads running than the total amount of nodes
      # and  c) there is more than MAX_INTER_JOB_GAP since last one was started
      # then we want one more thread (rationale is to fix hanging thread causing HOLB)
      return unless @want <= size && @want < @nodes.size

      return unless @want <= size

      increment if (Time.now.utc - @last) > MAX_INTER_JOB_GAP
    end
  end
end
