class NoopHook < Oxidized::Hook
  def validate_cfg!
    logger.info "Validate config"
  end

  def run_hook(ctx)
    logger.info "Run hook with context: #{ctx}"
  end
end
