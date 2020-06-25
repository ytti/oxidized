module Oxidized
  class GitCrypt < Output
    class GitCryptError < OxidizedError; end
    begin
      require 'git'
    rescue LoadError
      raise OxidizedError, 'git not found: sudo gem install git'
    end

    attr_reader :commitref

    def initialize
      @cfg = Oxidized.config.output.gitcrypt
      @gitcrypt_cmd = "/usr/bin/git-crypt"
      @gitcrypt_init = @gitcrypt_cmd + " init"
      @gitcrypt_unlock = @gitcrypt_cmd + " unlock"
      @gitcrypt_lock = @gitcrypt_cmd + " lock"
      @gitcrypt_adduser = @gitcrypt_cmd + " add-gpg-user --trusted "
    end

    def setup
      if @cfg.empty?
        Oxidized.asetus.user.output.gitcrypt.user  = 'Oxidized'
        Oxidized.asetus.user.output.gitcrypt.email = 'o@example.com'
        Oxidized.asetus.user.output.gitcrypt.repo = File.join(Config::Root, 'oxidized.git')
        Oxidized.asetus.save :user
        raise NoConfig, 'no output git config, edit ~/.config/oxidized/config'
      end

      if @cfg.repo.respond_to?(:each)
        @cfg.repo.each do |group, repo|
          @cfg.repo["#{group}="] = File.expand_path repo
        end
      else
        @cfg.repo = File.expand_path @cfg.repo
      end
    end

    def crypt_init(repo)
      repo.chdir do
        system(@gitcrypt_init)
        @cfg.users.each do |user|
          system("#{@gitcrypt_adduser} #{user}")
        end
        File.write(".gitattributes", "* filter=git-crypt diff=git-crypt\n.gitattributes !filter !diff")
        repo.add(".gitattributes")
        repo.commit("Initial commit: crypt all config files")
      end
    end

    def lock(repo)
      repo.chdir do
        system(@gitcrypt_lock)
      end
    end

    def unlock(repo)
      repo.chdir do
        system(@gitcrypt_unlock)
      end
    end

    def store(file, outputs, opt = {})
      @msg   = opt[:msg]
      @user  = (opt[:user]  || @cfg.user)
      @email = (opt[:email] || @cfg.email)
      @opt   = opt
      @commitref = nil
      repo = @cfg.repo

      outputs.types.each do |type|
        type_cfg = ''
        type_repo = File.join(File.dirname(repo), type + '.git')
        outputs.type(type).each do |output|
          (type_cfg << output; next) unless output.name # rubocop:disable Style/Semicolon
          type_file = file + '--' + output.name
          if @cfg.type_as_directory?
            type_file = type + '/' + type_file
            type_repo = repo
          end
          update type_repo, type_file, output
        end
        update type_repo, file, type_cfg
      end

      update repo, file, outputs.to_cfg
    end

    def fetch(node, group)
      repo, path = yield_repo_and_path(node, group)
      repo = Git.open repo
      unlock repo
      index = repo.index
      # Empty repo ?
      raise 'Empty git repo' if File.exist?(index.path)

      File.read path
      lock repo
    rescue StandardError
      'node not found'
    end

    # give a hash of all oid revision for the given node, and the date of the commit
    def version(node, group)
      repo, path = yield_repo_and_path(node, group)

      repo = Git.open repo
      unlock repo
      walker = repo.log.path(path)
      i = -1
      tab = []
      walker.each do |commit|
        hash = {}
        hash[:date] = commit.date.to_s
        hash[:oid] = commit.objectish
        hash[:author] = commit.author
        hash[:message] = commit.message
        tab[i += 1] = hash
      end
      walker.reset
      tab
    rescue StandardError
      'node not found'
    end

    # give the blob of a specific revision
    def get_version(node, group, oid)
      repo, path = yield_repo_and_path(node, group)
      repo = Git.open repo
      unlock repo
      repo.gtree(oid).files[path].contents
    rescue StandardError
      'version not found'
    ensure
      lock repo
    end

    # give a hash with the patch of a diff between 2 revision and the stats (added and deleted lines)
    def get_diff(node, group, oid1, oid2)
      diff_commits = nil
      repo, _path = yield_repo_and_path(node, group)
      repo = Git.open repo
      unlock repo
      commit = repo.gcommit(oid1)

      if oid2
        commit_old = repo.gcommit(oid2)
        diff = repo.diff(commit_old, commit)
        stats = [diff.stats[:files][node.name][:insertions], diff.stats[:files][node.name][:deletions]]
        diff.each do |patch|
          if /#{node.name}\s+/ =~ patch.patch.to_s.lines.first
            diff_commits = { patch: patch.patch.to_s, stat: stats }
            break
          end
        end
      else
        stat = commit.parents[0].diff(commit).stats
        stat = [stat[:files][node.name][:insertions], stat[:files][node.name][:deletions]]
        patch = commit.parents[0].diff(commit).patch
        diff_commits = { patch: patch, stat: stat }
      end
      lock repo
      diff_commits
    rescue StandardError
      'no diffs'
    ensure
      lock repo
    end

    private

    def yield_repo_and_path(node, group)
      repo, path = node.repo, node.name

      path = "#{group}/#{node.name}" if group && @cfg.single_repo?

      [repo, path]
    end

    def update(repo, file, data)
      return if data.empty?

      if @opt[:group]
        if @cfg.single_repo?
          file = File.join @opt[:group], file
        else
          repo = if repo.is_a?(::String)
                   File.join File.dirname(repo), @opt[:group] + '.git'
                 else
                   repo[@opt[:group]]
                 end
        end
      end

      begin
        update_repo repo, file, data, @msg, @user, @email
      rescue Git::GitExecuteError, ArgumentError => open_error
        Oxidized.logger.debug "open_error #{open_error} #{file}"
        begin
          grepo = Git.init repo
          crypt_init grepo
        rescue StandardError => create_error
          raise GitCryptError, "first '#{open_error.message}' was raised while opening git repo, then '#{create_error.message}' was while trying to create git repo"
        end
        retry
      end
    end

    def update_repo(repo, file, data, msg, user, email)
      grepo = Git.open repo
      grepo.config('user.name', user)
      grepo.config('user.email', email)
      grepo.chdir do
        unlock grepo
        File.write(file, data)
        grepo.add(file)
        if grepo.status[file].nil?
          grepo.commit(msg)
          @commitref = grepo.log(1).first.objectish
          true
        elsif !grepo.status[file].type.nil?
          grepo.commit(msg)
          @commitref = grepo.log(1).first.objectish
          true
        end
        lock grepo
      end
    end
  end
end
