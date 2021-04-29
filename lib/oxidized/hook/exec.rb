class Exec < Oxidized::Hook
  include Process

  def initialize
    super
    @timeout = 60
    @async = false
  end

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

  def run_hook(ctx)
    env = make_env ctx
    log "Execute: #{@cmd.inspect}", :debug
    th = Thread.new do
      begin
        run_cmd! env
      rescue StandardError => e
        raise e unless @async
      end
    end
    th.join unless @async
  end

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
        "OX_REPO_NAME"      => ctx.node.repo.to_s
      )
    end
    if ctx.job
      env["OX_JOB_STATUS"] = ctx.job.status.to_s
      env["OX_JOB_TIME"] = ctx.job.time.to_s
    end
    env
  end
end
