module Oxidized
  require 'oxidized/job'
  require 'oxidized/jobs'

  # Worker class manages jobs and node processing within Oxidized.
  # It runs in a continuous loop, processing jobs in parallel, and handles job success or failure.
  class Worker
    # Initializes the Worker object.
    #
    # @param nodes [Nodes] the nodes collection that the worker will process.
    def initialize(nodes)
      @jobs_done  = 0
      @nodes      = nodes
      @jobs       = Jobs.new(Oxidized.config.threads, Oxidized.config.use_max_threads, Oxidized.config.interval, @nodes)
      @nodes.jobs = @jobs
      Thread.abort_on_exception = true
    end

    # Main work method for processing jobs.
    # It checks the status of jobs, processes finished jobs, and adds new jobs to the queue.
    def work
      ended = []
      @jobs.delete_if { |job| ended << job unless job.alive? }
      ended.each      { |job| process job }
      @jobs.work

      # @!visibility private
      # Add new jobs if necessary
      while @jobs.size < @jobs.want
        Oxidized.logger.debug "lib/oxidized/worker.rb: Jobs running: #{@jobs.size} of #{@jobs.want} - ended: #{@jobs_done} of #{@nodes.size}"

        # @!visibility private
        # ask for next node in queue non destructive way
        nextnode = @nodes.first
        unless nextnode.last.nil?
          # @!visibility private
          # Set unobtainable value for 'last' if interval checking is disabled
          last = Oxidized.config.interval.zero? ? Time.now.utc + 10 : nextnode.last.end
          break if last + Oxidized.config.interval > Time.now.utc
        end

        # @!visibility private
        # shift nodes and get the next node
        node = @nodes.get
        node.running? ? next : node.running = true

        @jobs.push Job.new node
        Oxidized.logger.debug "lib/oxidized/worker.rb: Added #{node.group}/#{node.name} to the job queue"
      end

      if cycle_finished?
        run_done_hook
        exit 0 if Oxidized.config.run_once
      end

      Oxidized.logger.debug("lib/oxidized/worker.rb: #{@jobs.size} jobs running in parallel") unless @jobs.empty?
    end

    # Processes an individual job after it finishes.
    #
    # @param job [Job] the job to process.
    def process(job)
      node = job.node
      node.last = job
      node.stats.add job
      @jobs.duration job.time
      node.running = false
      if job.status == :success
        process_success node, job
      else
        process_failure node, job
      end
    rescue NodeNotFound
      Oxidized.logger.warn "#{node.group}/#{node.name} not found, removed while collecting?"
    end

    # Reloads the nodes from configuration.
    def reload
      @nodes.load
    end

    private

    # Handles the successful completion of a job.
    #
    # @param node [Node] the node whose job succeeded.
    # @param job [Job] the successful job.
    def process_success(node, job)
      @jobs_done += 1 # needed for :nodes_done hook
      Oxidized.hooks.handle :node_success, node: node,
                                           job:  job
      msg = "update #{node.group}/#{node.name}"
      msg += " from #{node.from}" if node.from
      msg += " with message '#{node.msg}'" if node.msg
      output = node.output.new
      if output.store node.name, job.config,
                      msg: msg, email: node.email, user: node.user, group: node.group
        node.modified
        Oxidized.logger.info "Configuration updated for #{node.group}/#{node.name}"
        Oxidized.hooks.handle :post_store, node:      node,
                                           job:       job,
                                           commitref: output.commitref
      end
      node.reset
    end

    # Handles the failure of a job.
    #
    # @param node [Node] the node whose job failed.
    # @param job [Job] the failed job.
    def process_failure(node, job)
      msg = "#{node.group}/#{node.name} status #{job.status}"
      if node.retry < Oxidized.config.retries
        node.retry += 1
        msg += ", retry attempt #{node.retry}"
        @nodes.next node.name
      else
        # @!visibility private
        # Only increment the @jobs_done when we give up retries for a node (or success).
        # As it would otherwise cause @jobs_done to be incremented with generic retries.
        # This would cause :nodes_done hook to desync from running at the end of the nodelist and
        # be fired when the @jobs_done > @nodes.count (could be mid-cycle on the next cycle).
        @jobs_done += 1
        msg += ", retries exhausted, giving up"
        node.retry = 0
        Oxidized.hooks.handle :node_fail, node: node,
                                          job:  job
      end
      Oxidized.logger.warn msg
    end

    # Determines if a job cycle has finished.
    #
    # @return [Boolean] true if the job cycle is finished, otherwise false.
    def cycle_finished?
      if @jobs_done > @nodes.count
        true
      else
        @jobs_done.positive? && (@jobs_done % @nodes.count).zero?
      end
    end

    # Runs the :nodes_done hook after all jobs in the cycle are complete.
    def run_done_hook
      Oxidized.logger.debug "lib/oxidized/worker.rb: Running :nodes_done hook"
      Oxidized.hooks.handle :nodes_done
    rescue StandardError => e
      # @!visibility private
      # swallow the hook erros and continue as normal
      Oxidized.logger.error "lib/oxidized/worker.rb: #{e.message}"
    ensure
      @jobs_done = 0
    end
  end
end
