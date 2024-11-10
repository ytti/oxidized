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
          Oxidized.asetus.user.output.git.repo = File.join(Config::ROOT, 'oxidized.git')
          Oxidized.asetus.save :user
          raise NoConfig, "no output git config, edit #{Oxidized::Config.configfile}"
        end

        if @cfg.repo.respond_to?(:each)
          @cfg.repo.each do |group, repo|
            @cfg.repo["#{group}="] = File.expand_path repo
          end
        else
          @cfg.repo = File.expand_path @cfg.repo
        end
      end

      def store(node.name, outputs, opt = {})
        @msg   = opt[:msg]
        @user  = node.user  || @cfg.user
        @email = node.email || @cfg.email
        @opt   = opt
        @commitref = nil
        repo = @cfg.repo

        outputs.types.each do |type|
          type_cfg = ''
          type_repo = File.join(File.dirname(repo), type + '.git')
          outputs.type(type).each do |output|
            (type_cfg << output; next) unless output.name # rubocop:disable Style/Semicolon
            type_file = node.name + '--' + output.name
            if @cfg.type_as_directory?
              type_file = type + '/' + type_file
              type_repo = repo
            end
            update type_repo, type_file, output
          end
          update type_repo, node.name, type_cfg
        end

        update repo, node.name, outputs.to_cfg
      end

      # Returns the configuration of group/node_name
      #
      # #fetch is called by Nodes#fetch
      # Nodes#fetch creates a new Output object each time, so we cannot
      # store the repo index in memory. But as we keep the repo index up
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

      # give a hash of all oid revision for the given node, and the date of the commit
      def version(node, group)
        repo, path = yield_repo_and_path(node, group)

        repo = Rugged::Repository.new repo
        walker = Rugged::Walker.new(repo)
        walker.sorting(Rugged::SORT_DATE)
        walker.push(repo.head.target.oid)
        i = -1
        tab = []
        walker.each do |commit|
          # Diabled rubocop because the suggested .empty? does not work here.
          next if commit.diff(paths: [path]).size.zero? # rubocop:disable Style/ZeroLengthPredicate

          hash = {}
          hash[:date] = commit.time.to_s
          hash[:oid] = commit.oid
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

      private

      def yield_repo_and_path(node, group)
        repo, path = node.repo, node.name

        path = "#{group}/#{node.name}" if group && !group.empty? && @cfg.single_repo?

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
          repo = Rugged::Repository.new repo
          update_repo repo, file, data
        rescue Rugged::OSError, Rugged::RepositoryError => e
          begin
            Rugged::Repository.init_at repo, :bare
          rescue StandardError => create_error
            raise GitError, "first '#{e.message}' was raised while opening git repo, then '#{create_error.message}' was while trying to create git repo"
          end
          retry
        end
      end

      # Uploads data into file in the repo
      #
      # @param [String] file: the file to save the configuration to
      # @param [String] data: the configuration to save
      # @param [Rugged::Repository] repo: the git repository to use
      #
      # If Oxidized.config.output.git.single_repo = false (which is the default),
      # there will one repository for each group.
      #
      # update_repo caches the index on disk. An index is usually used in a
      # working directory and not in a bare repository, which confuses users.
      # The alternative would be to rebuild the index each time, which a little
      # time consuming. Caching the index in memory is difficult because a new
      # Output object is created each time #store is called.
      def update_repo(repo, file, data)
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
