module Oxidized
  require 'oxidized/job'
  require 'oxidized/jobs'
  class Worker
    def initialize nodes
      @nodes   = nodes
      @jobs    = Jobs.new CFG.threads, CFG.interval, @nodes
      Thread.abort_on_exception = true
    end
    def work
      ended = []
      @jobs.delete_if { |job| ended << job if not job.alive? }
      ended.each      { |job| process job }
      while @jobs.size < @jobs.want
        Log.debug "Jobs #{@jobs.size}, Want: #{@jobs.want}"
        # ask for next node in queue non destructive way
        nextnode = @nodes.first
        unless nextnode.last.nil?
          break if nextnode.last.end + CFG.interval > Time.now.utc
        end
        # shift nodes and get the next node
        node = @nodes.get
        node.running? ? next : node.running = true
        @jobs.push Job.new node
      end
    end
    def process job
      node = job.node
      node.last = job
      node.stats.add job
      @jobs.duration job.time
      node.running = false
      if job.status == :success
        msg = "update #{node.name}"
        msg += " from #{node.from}" if node.from
        msg += " with message '#{node.msg}'" if node.msg
        node.output.new.store node.name, job.config,
                              :msg => msg, :user => node.user, :group => node.group
      else
        msg = "#{node.name} status #{job.status}"
        if node.retry < CFG.retries
          node.retry += 1
          msg += ", retry attempt #{node.retry}"
          @nodes.next node.name
        else
          msg += ", retries exhausted, giving up"
          node.retry = 0
        end
        Log.warn msg
      end
      node.reset
    end
  end
end
