class GithubRepo < Oxidized::Hook
  def validate_cfg!
    raise KeyError, 'hook.remote_repo is required' unless cfg.has_key?('remote_repo')
  end

  def run_hook(ctx)
    repo  = Rugged::Repository.new(ctx.node.repo)
    creds = credentials(ctx.node)
    url   = remote_repo(ctx.node)

    if url.nil? || url.empty?
      log "No repository defined for #{ctx.node.group}/#{ctx.node.name}", :debug
      return
    end

    log "Pushing local repository(#{repo.path})..."
    log "to remote: #{url}"

    if repo.remotes['origin'].nil?
      repo.remotes.create('origin', url)
    elsif repo.remotes['origin'].url != url
      repo.remotes.set_url('origin', url)
    end
    remote = repo.remotes['origin']

    fetch_and_merge_remote(repo, creds)

    remote.push([repo.head.name], credentials: creds)
  end

  def fetch_and_merge_remote(repo, creds)
    result = repo.fetch('origin', [repo.head.name], credentials: creds)
    log result.inspect, :debug

    unless result[:total_deltas].positive?
      log "nothing received after fetch", :debug
      return
    end

    their_branch = repo.branches["origin/master"]

    log "merging fetched branch #{their_branch.name}", :debug

    merge_index = repo.merge_commits(repo.head.target_id, their_branch.target_id)

    if merge_index.conflicts?
      log("Conflicts detected, skipping Rugged::Commit.create", :warn)
      return
    end

    Rugged::Commit.create(repo,
                          parents:    [repo.head.target, their_branch.target],
                          tree:       merge_index.write_tree(repo),
                          message:    "Merge remote-tracking branch '#{their_branch.name}'",
                          update_ref: "HEAD")
  end

  private

  def credentials(node)
    Proc.new do |_url, username_from_url, _allowed_types| # rubocop:disable Style/Proc
      git_user = cfg.has_key?('username') ? cfg.username : (username_from_url || 'git')
      if cfg.has_key?('password')
        log "Authenticating using username and password as '#{git_user}'", :debug
        Rugged::Credentials::UserPassword.new(username: git_user, password: cfg.password)
      elsif cfg.has_key?('privatekey')
        pubkey = cfg.has_key?('publickey') ? cfg.publickey : nil
        log "Authenticating using ssh keys as '#{git_user}'", :debug
        rugged_sshkey(git_user: git_user, privkey: cfg.privatekey, pubkey: pubkey)
      elsif cfg.has_key?('remote_repo') && cfg.remote_repo.has_key?(node.group) && cfg.remote_repo[node.group].has_key?('privatekey')
        pubkey = cfg.remote_repo[node.group].has_key?('publickey') ? cfg.remote_repo[node.group].publickey : nil
        log "Authenticating using ssh keys as '#{git_user}' for '#{node.group}/#{node.name}'", :debug
        rugged_sshkey(git_user: git_user, privkey: cfg.remote_repo[node.group].privatekey, pubkey: pubkey)
      else
        log "Authenticating using ssh agent as '#{git_user}'", :debug
        Rugged::Credentials::SshKeyFromAgent.new(username: git_user)
      end
    end
  end

  def rugged_sshkey(args = {})
    git_user   = args[:git_user]
    privkey    = args[:privkey]
    pubkey     = args[:pubkey] || (privkey + '.pub')
    Rugged::Credentials::SshKey.new(username:   git_user,
                                    publickey:  File.expand_path(pubkey),
                                    privatekey: File.expand_path(privkey),
                                    passphrase: ENV.fetch("OXIDIZED_SSH_PASSPHRASE", nil))
  end

  def remote_repo(node)
    if node.group.nil? || cfg.remote_repo.is_a?(String)
      cfg.remote_repo
    elsif cfg.remote_repo[node.group].is_a?(String)
      cfg.remote_repo[node.group]
    elsif cfg.remote_repo[node.group].url.is_a?(String)
      cfg.remote_repo[node.group].url
    end
  end
end
