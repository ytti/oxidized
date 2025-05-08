class NoopHook < Oxidized::Hook
  def validate_cfg!
    log "Validate config"
  end

  def run_hook(ctx)
    log "Run hook with context: #{ctx}"
  end
end
