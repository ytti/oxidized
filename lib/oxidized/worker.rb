module Oxidized
  require 'oxidized/job'
  require 'oxidized/jobs'
  class Worker
    def initialize nodes
      @jobs_done  = 0
      @nodes      = nodes
      @jobs       = Jobs.new(Oxidized.config.threads, Oxidized.config.interval, @nodes)
      @nodes.jobs = @jobs
      Thread.abort_on_exception = true
    end

    def work
      ended = []
      @jobs.delete_if { |job| ended << job if not job.alive? }
      ended.each      { |job| process job }
      @jobs.work

      while @jobs.size < @jobs.want
        Oxidized.logger.debug "lib/oxidized/worker.rb: Jobs running: #{@jobs.size} of #{@jobs.want} - ended: #{@jobs_done} of #{@nodes.size}"
        # ask for next node in queue non destructive way
        nextnode = @nodes.first
        unless nextnode.last.nil?
          # Set unobtainable value for 'last' if interval checking is disabled
          last = Oxidized.config.interval == 0 ? Time.now.utc + 10 : nextnode.last.end
          break if last + Oxidized.config.interval > Time.now.utc
        end
        # shift nodes and get the next node
        node = @nodes.get
        node.running? ? next : node.running = true
        @jobs.push Job.new node
        Oxidized.logger.debug "lib/oxidized/worker.rb: Added #{node.name} to the job queue"
      end

      run_done_hook if is_cycle_finished?
      Oxidized.logger.debug("lib/oxidized/worker.rb: #{@jobs.size} jobs running in parallel") unless @jobs.empty?
    end

    def process job
      node = job.node
      node.last = job
      node.stats.add job
      @jobs.duration job.time
      node.running = false
      @jobs_done += 1 # needed for worker_done event

      if job.status == :success
        Oxidized.Hooks.handle :node_success, :node => node,
                                             :job => job
        msg = "update #{node.name}"
        msg += " from #{node.from}" if node.from
        msg += " with message '#{node.msg}'" if node.msg
        output = node.output.new
        if output.store node.name, job.config,
                              :msg => msg, :email => node.email, :user => node.user, :group => node.group
          Oxidized.logger.info "Configuration updated for #{node.group}/#{node.name}"
          Oxidized.Hooks.handle :post_store, :node => node,
                                             :job => job,
                                             :commitref => output.commitref
        end
        node.reset
      else
        msg = "#{node.name} status #{job.status}"
        if node.retry < Oxidized.config.retries
          node.retry += 1
          msg += ", retry attempt #{node.retry}"
          @nodes.next node.name
        else
          msg += ", retries exhausted, giving up"
          node.retry = 0
          Oxidized.Hooks.handle :node_fail, :node => node,
                                            :job => job
        end
        Oxidized.logger.warn msg
      end
    rescue NodeNotFound
      Oxidized.logger.warn "#{node.name} not found, removed while collecting?"
    end

    private

    def is_cycle_finished?
      @jobs_done > 0 && @jobs_done % @nodes.count == 0
    end

    def run_done_hook
      Oxidized.logger.debug "lib/oxidized/worker.rb: Running :nodes_done hook"
      Oxidized.Hooks.handle :nodes_done
    rescue => e
      # swallow the hook erros and continue as normal
      Oxidized.logger.error "lib/oxidized/worker.rb: #{e.message}"
    ensure
      @jobs_done = 0
    end
  end
end
