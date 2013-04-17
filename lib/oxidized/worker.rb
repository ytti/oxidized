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
        node = @nodes.get
        node.running? ? next : node.running = true
        @jobs.push Job.new node
      end
    end
    def process job
      node = job.node
      node.last = job
      @jobs.duration job.time
      if job.status == :success
        node.output.new.update node.name, job.config, 
                               :msg => "update #{node.name}", :group => node.group
      else
        Log.warn "#{node.name} status #{job.status}"
      end
      node.running = false
    end
  end
end
