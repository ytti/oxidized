class GithubRepo < Oxidized::Hook
  def validate_cfg!
    cfg.has_key?('remote_repo') or raise KeyError, 'remote_repo is required'
  end

  def run_hook(ctx)
    credentials =  Rugged::Credentials::SshKeyFromAgent.new(username: 'git')
    repo = Rugged::Repository.new(Oxidized.config.output.git.repo)
    log "Pushing local repository(#{repo.path})..."
    remote = repo.remotes['origin'] || repo.remotes.create('origin', cfg.remote_repo)
    log "to remote: #{remote.url}"
    remote.push(['refs/heads/master'], credentials: credentials)
  end
end
