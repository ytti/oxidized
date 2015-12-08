class GithubRepo < Oxidized::Hook
  def validate_cfg!
    cfg.has_key?('remote_repo') or raise KeyError, 'remote_repo is required'
  end

  def run_hook(ctx)
    credentials = Rugged::Credentials::UserPassword.new(username: cfg.username, password: cfg.password)
    repo = Rugged::Repository.new(Oxidized.config.output.git.repo)
    log "Pushing local repository(#{repo.path})..."
    remote = repo.remotes['origin'] || repo.remotes.create('origin', cfg.remote_repo)
    log "to remote: #{remote.url}"

    fetch_and_merge_remote(repo, credentials)

    remote.push([repo.head.name], credentials: credentials)
  end

  def fetch_and_merge_remote(repo, credentials)
    repo.fetch('origin', [repo.head.name], credentials: credentials)

    their_branch = repo.branches["origin/master"] or return

    merge_index = repo.merge_commits(repo.head.target_id, their_branch.target_id)

    log("Conflicts detected", :warn) if merge_index.conflicts?

    Rugged::Commit.create(repo, {
      parents: [repo.head.target, their_branch.target],
      tree: merge_index.write_tree(repo),
      message: "Merge remote-tracking branch '#{their_branch.name}'",
      update_ref: "HEAD"
    })
  end
end
