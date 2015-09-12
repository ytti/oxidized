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
      @jobs.work
      while @jobs.size < @jobs.want
        Log.debug "Jobs #{@jobs.size}, Want: #{@jobs.want}"
        node = @nodes.get
        unless node.force or node.last.nil?
          break if node.last.end + CFG.interval > Time.now.utc
        end
        node.running? ? next : node.running = true
        node.force = false if node.force
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
        Oxidized.Hooks.handle :node_success, :node => node,
                                             :job => job
        msg = "update #{node.name}"
        msg += " from #{node.from}" if node.from
        msg += " with message '#{node.msg}'" if node.msg
        if node.output.new.store node.name, job.config,
                              :msg => msg, :user => node.user, :group => node.group
          Log.info "Configuration updated for #{node.group}/#{node.name}"
          Oxidized.Hooks.handle :post_store, :node => node,
                                             :job => job
        end
        node.reset
      else
        msg = "#{node.name} status #{job.status}"
        if node.retry < CFG.retries
          node.retry += 1
          msg += ", retry attempt #{node.retry}"
          @nodes.next node.name
        else
          msg += ", retries exhausted, giving up"
          node.retry = 0
          Oxidized.Hooks.handle :node_fail, :node => node,
                                            :job => job
        end
        Log.warn msg
      end
    rescue NodeNotFound
      Log.warn "#{node.name} not found, removed while collecting?"
    end

  end
end
