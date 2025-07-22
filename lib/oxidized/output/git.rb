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

        update repo, file, outputs.to_cfg
      end

      # Returns the configuration of group/node_name
      #
      # #fetch is called by Nodes#fetch
      # Nodes#fetch creates a new Output object each time, so it not easy
      # to cache the repo index in memory. But as we keep the repo index up
      # to date on disk in #update_repo, we can read it from disk instead of
      # rebuilding it each time.
      def fetch(node, group)
        repo, path = yield_repo_and_path(node, group)
        repo = Rugged::Repository.new repo
        # Read the index from disk
        index = repo.index

        repo.read(index.get(path)[:oid]).data
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

      # Update @gitcache, a class instance variable, ensuring persistence
      # by saving the cache independently of object instances
      def self.update_cache(repo_path)
        # initialize our cache as a class instance variable
        @gitcache ||= {}
        # When single_repo == false, we have multiple repositories
        unless @gitcache[repo_path]
          @gitcache[repo_path] = {}
          @gitcache[repo_path][:nodes] = {}
          @gitcache[repo_path][:last_commit] = nil
        end

        repo = Rugged::Repository.new repo_path

        walker = Rugged::Walker.new(repo)
        walker.sorting(Rugged::SORT_DATE)
        walker.push(repo.head.target.oid)

        # We store the commits into a temporary cache. It will be prepended
        # to @gitcache to preserve the order of the commits.
        cache = {}
        walker.each do |commit|
          if commit.oid == @gitcache[repo_path][:last_commit]
            # we have reached the last cached commit, so we're done
            break
          end

          commit.diff.each_delta do |delta|
            next unless delta.added? || delta.modified?

            hash = {}
            # We keep :date for reverse compatibility on oxidized-web <= 0.15.1
            hash[:date] = commit.time.to_s
            # date as a Time instance for more flexibility in oxidized-web
            hash[:time] = commit.time
            hash[:oid] = commit.oid
            hash[:author] = commit.author
            hash[:message] = commit.message

            filename = delta.new_file[:path]
            if cache[filename]
              cache[filename].append hash
            else
              cache[filename] = [hash]
            end
          end
        end

        cache.each_pair do |filename, hashlist|
          if @gitcache[repo_path][:nodes][filename]
            # using the splat operator (*) should be OK as hashlist should
            # not be very big when working on deltas
            @gitcache[repo_path][:nodes][filename].prepend(*hashlist)
          else
            @gitcache[repo_path][:nodes][filename] = hashlist
          end
        end

        # Store the most recent commit
        @gitcache[repo_path][:last_commit] = repo.head.target.oid
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
      # update_repo caches the index on disk. An index is usually used in a
      # working directory and not in a bare repository, which confuses users.
      # The alternative would be to rebuild the index each time, which a little
      # time consuming. Caching the index in memory is difficult because a new
      # Output object is created each time #store is called.
      def update_repo(repo, file, data) # rubocop:disable Naming/PredicateMethod
        oid_old = repo.blob_at(repo.head.target_id, file) rescue nil
        return false if oid_old && (oid_old.content.b == data.b)

        oid = repo.write data, :blob
        # Read the index from disk
        index = repo.index
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
