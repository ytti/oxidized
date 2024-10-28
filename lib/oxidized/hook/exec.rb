module Oxidized
  module Hook
    # The Exec class is a hook for Oxidized that allows the execution of external
    # commands or scripts in response to specific events within the Oxidized workflow.
    #
    # This class provides the ability to define a command to run, along with
    # configurable options such as a timeout and whether to execute the command
    # asynchronously. It captures various context parameters related to the
    # event, node, and job, which are passed to the executed command via environment
    # variables.
    #
    # This class is particularly useful for users who want to trigger custom scripts
    # or processes as part of their network device management and automation tasks,
    # enhancing the flexibility of the Oxidized framework.
    class Exec < Oxidized::Hook
      include Process

      # Initializes an Exec hook instance.
      #
      # Sets default values for timeout and async execution.
      def initialize
        super
        @timeout = 60
        @async = false
      end

      # Validates the configuration for the Exec hook.
      #
      # Checks the provided configuration for timeout, async execution, and command.
      # Raises an ArgumentError if any configuration value is invalid.
      #
      # @raise [ArgumentError] if configuration is invalid.
      def validate_cfg!
        # Syntax check
        if cfg.has_key? "timeout"
          @timeout = cfg.timeout
          raise "invalid timeout value" unless @timeout.is_a?(Integer) &&
                                               @timeout.positive?
        end

        @async = !!cfg.async if cfg.has_key? "async"

        if cfg.has_key? "cmd"
          @cmd = cfg.cmd
          raise "invalid cmd value" unless @cmd.is_a?(String) || @cmd.is_a?(Array)
        end
      rescue RuntimeError => e
        raise ArgumentError,
              "#{self.class.name}: configuration invalid: #{e.message}"
      end

      # Executes the configured command in a new thread.
      #
      # @param ctx [HookContext] the context in which the hook is executed.
      # @return [void]
      def run_hook(ctx)
        env = make_env ctx
        log "Execute: #{@cmd.inspect}", :debug
        th = Thread.new do
          run_cmd! env
        rescue StandardError => e
          raise e unless @async
        end
        th.join unless @async
      end

      # Runs the command with a timeout.
      #
      # @param env [Hash] the environment variables to be passed to the command.
      # @raise [Timeout::Error] if the command exceeds the specified timeout.
      # @raise [RuntimeError] if the command fails with a non-zero exit status.
      def run_cmd!(env)
        pid, status = nil, nil
        Timeout.timeout(@timeout) do
          pid = spawn env, @cmd, unsetenv_others: true
          pid, status = wait2 pid
          unless status.exitstatus.zero?
            msg = "#{@cmd.inspect} failed with exit value #{status.exitstatus}"
            log msg, :error
            raise msg
          end
        end
      rescue Timeout::Error
        kill "TERM", pid
        msg = "#{@cmd} timed out"
        log msg, :error
        raise Timeout::Error, msg
      end

      # Creates an environment hash from the context.
      #
      # @param ctx [HookContext] the context from which to extract information.
      # @return [Hash] environment variables to be passed to the command.
      def make_env(ctx)
        env = {
          "OX_EVENT" => ctx.event.to_s
        }
        if ctx.node
          env.merge!(
            "OX_NODE_NAME"      => ctx.node.name.to_s,
            "OX_NODE_IP"        => ctx.node.ip.to_s,
            "OX_NODE_FROM"      => ctx.node.from.to_s,
            "OX_NODE_MSG"       => ctx.node.msg.to_s,
            "OX_NODE_GROUP"     => ctx.node.group.to_s,
            "OX_NODE_MODEL"     => ctx.node.model.class.name,
            "OX_REPO_COMMITREF" => ctx.commitref.to_s,
            "OX_REPO_NAME"      => ctx.node.repo.to_s,
            "OX_ERR_TYPE"       => ctx.node.err_type.to_s,
            "OX_ERR_REASON"     => ctx.node.err_reason.to_s
          )
        end
        if ctx.job
          env["OX_JOB_STATUS"] = ctx.job.status.to_s
          env["OX_JOB_TIME"] = ctx.job.time.to_s
        end
        env
      end
    end
  end
end
