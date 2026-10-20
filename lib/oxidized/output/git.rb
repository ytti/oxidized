module Oxidized
  module Output
    class Git < Output
      using Refinements

      class GitError < OxidizedError; end
      begin
        require 'rugged'
      rescue LoadError
        raise OxidizedError, 'rugged not found: sudo gem install rugged'
      end

      attr_reader :commitref

      def initialize
        super
        @cfg = Oxidized.config.output.git
      end

      def setup
        if @cfg.empty?
          Oxidized.asetus.user.output.git.user  = 'Oxidized'
          Oxidized.asetus.user.output.git.email = 'o@example.com'
          Oxidized.asetus.user.output.git.repo = ::File.join(Config::ROOT, 'oxidized.git')
          Oxidized.asetus.save :user
          raise NoConfig, "no output git config, edit #{Oxidized::Config.configfile}"
        end

        if @cfg.repo.respond_to?(:each)
          @cfg.repo.each do |group, repo|
            @cfg.repo["#{group}="] = ::File.expand_path repo
          end
        else
          @cfg.repo = ::File.expand_path @cfg.repo
        end
      end

      # file: node name (String)
      # outputs: Oxidized::Models::Outputs
      # opts: dict of optional parameters:
      #  - msg: commit message
      #  - email: committer email
      #  - user: committer name
      #  - group: node group
      #  - significant_changes:
      #      nil / not set / true: store as usual
      #      false: skip general config, only store configs where type != nil
      def store(file, outputs, opt = {})
        @msg   = opt[:msg]
        @user  = opt[:user]  || @cfg.user
        @email = opt[:email] || @cfg.email
        @opt   = opt
        @commitref = nil
        repo = @cfg.repo

        outputs.types.each do |type|
          type_cfg = ''
          type_repo = ::File.join(::File.dirname(repo), type + '.git')
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

        update repo, file, outputs.to_cfg unless opt[:significant_changes] == false
      end

      # Returns the configuration of group/node_name
      #
      # #fetch is called by Nodes#fetch
      def fetch(node, group)
        repo, path = yield_repo_and_path(node, group)
        repo = Rugged::Repository.new repo
        repo.blob_at(repo.head.target_id, path).content
      rescue StandardError
        'node not found'
      end

      # give a hash of all oid revisions for the given node, and the date of
      # the commit.
      #
      # Called by Nodes#version
      def version(node, group)
        repo_path, node_path = yield_repo_and_path(node, group)
        self.class.hash_list(node_path, repo_path)
      rescue StandardError
        'node not found'
      end

      # give the blob of a specific revision
      def get_version(node, group, oid)
        repo, path = yield_repo_and_path(node, group)
        repo = Rugged::Repository.new repo
        repo.blob_at(oid, path).content
      rescue StandardError
        'version not found'
      end

      # give a hash with the patch of a diff between 2 revision and the stats (added and deleted lines)
      def get_diff(node, group, oid1, oid2)
        diff_commits = nil
        repo, = yield_repo_and_path(node, group)
        repo = Rugged::Repository.new repo
        commit = repo.lookup(oid1)

        if oid2
          commit_old = repo.lookup(oid2)
          diff = repo.diff(commit_old, commit)
          diff.each do |patch|
            if /#{node.name}\s+/ =~ patch.to_s.lines.first
              diff_commits = { patch: patch.to_s, stat: patch.stat }
              break
            end
          end
        else
          stat = commit.parents[0].diff(commit).stat
          stat = [stat[1], stat[2]]
          patch = commit.parents[0].diff(commit).patch
          diff_commits = { patch: patch, stat: stat }
        end

        diff_commits
      rescue StandardError
        'no diffs'
      end

      # Return the list of oids for node_path in the repository repo_path
      def self.hash_list(node_path, repo_path)
        update_cache(repo_path)
        @gitcache[repo_path][:nodes][node_path] || []
      end

      # As oxidized-web works with multiple threads, we need a mutex to protect the cache
      @cache_mutex = Mutex.new

      # Update @gitcache, a class instance variable, ensuring persistence
      # by saving the cache independently of object instances
      def self.update_cache(repo_path)
        @cache_mutex.synchronize do
          # @gitcache (class instance variable) is keyed by repo_path:
          # with single_repo == false, each group has its own repo
          @gitcache ||= {}
          repo = Rugged::Repository.new repo_path
          # Read HEAD only once, as a worker may commit while we walk the logs
          head_oid = repo.head.target.oid
          cache = @gitcache[repo_path]

          if cache && cache[:last_commit] == head_oid
            logger.debug "update_cache: #{repo_path} unchanged since last update, using cached versions"
            return cache
          end

          walker = Rugged::Walker.new(repo)
          walker.sorting(Rugged::SORT_TOPO | Rugged::SORT_DATE)
          walker.push(head_oid)
          if cache.nil?
            logger.debug "update_cache: building cache for #{repo_path}"
            cache = { nodes: {}, last_commit: nil }
          elsif descendant?(repo, head_oid, cache[:last_commit])
            logger.debug "update_cache: walking new commits in #{repo_path}"
            walker.hide(cache[:last_commit])
          else
            logger.warn "update_cache: history of #{repo_path} rewritten, rebuilding cache"
            cache = { nodes: {}, last_commit: nil }
          end

          new_commits = Hash.new { |hash, key| hash[key] = [] }
          walker.each do |commit|
            commit.diff.each_delta do |delta|
              next unless delta.added? || delta.modified?

              new_commits[delta.new_file[:path]] << {
                # We keep :date for reverse compatibility on oxidized-web <= 0.15.1
                date:    commit.time.to_s,
                # date as a Time instance for more flexibility in oxidized-web
                time:    commit.time,
                oid:     commit.oid,
                author:  commit.author,
                message: commit.message
              }
            end
          end

          # Build new arrays instead of modifying them, as lists returned
          # by hash_list may be in use by another thread
          new_commits.each_pair do |filename, hashlist|
            cache[:nodes][filename] = hashlist + (cache[:nodes][filename] || [])
          end

          cache[:last_commit] = head_oid
          @gitcache[repo_path] = cache
        end
      end

      # True if ancestor is in the history of commit, false if not or if
      # ancestor does not exist (e.g. after a history rewrite)
      def self.descendant?(repo, commit, ancestor)
        repo.descendant_of?(commit, ancestor)
      rescue Rugged::Error
        false
      end

      # Currently only used in unit tests
      def self.clear_cache
        @gitcache = nil
      end

      def self.clean_obsolete_nodes(active_nodes)
        git_config = Oxidized.config.output.git
        repo_path = git_config.repo

        unless git_config.single_repo?
          logger.warn "clean_obsolete_nodes is not implemented for " \
                      "multiple git repositories"
          return
        end

        if git_config.type_as_directory?
          logger.warn "clean_obsolete_nodes is not implemented for output " \
                      "types as a directory within the git repository"
          return
        end

        # The repo might not exist on the first run
        return unless ::File.directory?(repo_path)

        repo = Rugged::Repository.new repo_path
        return if repo.empty?

        keep_files = active_nodes.map do |n|
          n.group ? ::File.join(n.group, n.name) : n.name
        end

        tree = repo.last_commit.tree
        files_to_delete = []

        tree.walk_blobs do |root, entry|
          file_path = root.empty? ? entry[:name] : ::File.join(root, entry[:name])
          files_to_delete << file_path unless keep_files.include?(file_path)
        end

        return if files_to_delete.empty?

        logger.info "clean_obsolete_nodes: removing " \
                    "#{files_to_delete.size} obsolete configs"
        index = repo.index
        index.read_tree(tree)

        files_to_delete.each { |file_path| index.remove(file_path) }

        repo.config['user.name']  = git_config.user
        repo.config['user.email'] = git_config.email
        Rugged::Commit.create(
          repo,
          tree:       index.write_tree(repo),
          message:    "Removing #{files_to_delete.size} obsolete configs",
          parents:    [repo.head.target].compact,
          update_ref: 'HEAD'
        )

        index.write
      end

      private

      def yield_repo_and_path(node, group)
        repo = node.repo
        path = node.name

        path = "#{group}/#{node.name}" if group && !group.empty? && @cfg.single_repo?

        [repo, path]
      end

      def update(repo, file, data)
        return if data.empty?

        if @opt[:group]
          if @cfg.single_repo?
            file = ::File.join @opt[:group], file
          else
            repo = if repo.is_a?(::String)
                     ::File.join ::File.dirname(repo), @opt[:group] + '.git'
                   else
                     repo[@opt[:group]]
                   end
          end
        end

        begin
          repo = Rugged::Repository.new repo
          update_repo repo, file, data
        rescue Rugged::OSError, Rugged::RepositoryError => e
          begin
            Rugged::Repository.init_at repo, :bare
          rescue StandardError => create_error
            raise GitError, "first '#{e.message}' was raised while opening git repo, then '#{create_error.message}' " \
                            "was while trying to create git repo"
          end
          retry
        end
      end

      # Uploads data into file in the repository repo
      #
      # The index is rebuilt from HEAD, as HEAD may have been changed without
      # updating the index (e.g. by the githubrepo hook). It is still written
      # to disk, so that older versions of Oxidized do not use a stale index.
      def update_repo(repo, file, data) # rubocop:disable Naming/PredicateMethod
        oid_old = repo.blob_at(repo.head.target_id, file) rescue nil
        return false if oid_old && (oid_old.content.b == data.b)

        oid = repo.write data, :blob
        index = repo.index
        repo.empty? ? index.clear : index.read_tree(repo.head.target.tree)
        index.add path: file, oid: oid, mode: 0o100644

        repo.config['user.name']  = @user
        repo.config['user.email'] = @email
        @commitref = Rugged::Commit.create(repo,
                                           tree:       index.write_tree(repo),
                                           message:    @msg,
                                           parents:    repo.empty? ? [] : [repo.head.target].compact,
                                           update_ref: 'HEAD')

        index.write
        true
      end
    end
  end
end
