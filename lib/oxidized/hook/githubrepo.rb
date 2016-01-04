class GithubRepo < Oxidized::Hook
  def validate_cfg!
    cfg.has_key?('remote_repo') or raise KeyError, 'remote_repo is required'
  end

  def run_hook(ctx)
    repo = Rugged::Repository.new(Oxidized.config.output.git.repo)
    log "Pushing local repository(#{repo.path})..."
    remote = repo.remotes['origin'] || repo.remotes.create('origin', cfg.remote_repo)
    log "to remote: #{remote.url}"

    fetch_and_merge_remote(repo)

    remote.push([repo.head.name], credentials: credentials)
  end

  def fetch_and_merge_remote(repo)
    result = repo.fetch('origin', [repo.head.name], credentials: credentials)
    log result.inspect, :debug

    unless result[:total_deltas] > 0
      log "nothing recieved after fetch", :debug
      return
    end

    their_branch = repo.branches["origin/master"]

    log "merging fetched branch #{their_branch.name}", :debug

    merge_index = repo.merge_commits(repo.head.target_id, their_branch.target_id)

    if merge_index.conflicts?
      log("Conflicts detected, skipping Rugged::Commit.create", :warn)
      return
    end

    Rugged::Commit.create(repo, {
      parents: [repo.head.target, their_branch.target],
      tree: merge_index.write_tree(repo),
      message: "Merge remote-tracking branch '#{their_branch.name}'",
      update_ref: "HEAD"
    })
  end

  private

  def credentials
    @credentials ||= if cfg.has_key?('username') && cfg.has_key?('password')
      log "Using https auth", :debug
      Rugged::Credentials::UserPassword.new(username: cfg.username, password: cfg.password)
    else
      log "Using ssh auth", :debug
      Rugged::Credentials::SshKeyFromAgent.new(username: 'git')
    end
  end

end
