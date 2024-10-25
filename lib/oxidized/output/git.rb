module Oxidized
  module Output
    # Handles Git-based output for storing configurations in Oxidized.
    #
    # This class extends the Output module and provides methods for
    # storing and fetching configurations using a Git repository.
    class Git < Output
      using Refinements

      require 'oxidized//error/giterror'

      attr_reader :commitref

      # Initializes the Git output instance.
      #
      # @return [void]
      def initialize
        super
        @cfg = Oxidized.config.output.git
      end

      # Sets up the Git configuration for output.
      #
      # @raise [NoConfig] if no output Git configuration is provided.
      # @return [void]
      def setup
        if @cfg.empty?
          Oxidized.asetus.user.output.git.user  = 'Oxidized'
          Oxidized.asetus.user.output.git.email = 'o@example.com'
          Oxidized.asetus.user.output.git.repo = File.join(Config::ROOT, 'oxidized.git')
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

      # Stores the configuration output for a specified node.
      #
      # @param file [String] The file name to store the configuration under.
      # @param outputs [Object] The configuration outputs to store.
      # @param opt [Hash] Optional parameters for storage, such as message, user, and email.
      # @return [void]
      def store(file, outputs, opt = {})
        @msg   = opt[:msg]
        @user  = opt[:user]  || @cfg.user
        @email = opt[:email] || @cfg.email
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

      # Fetches the configuration for a specified node and group.
      #
      # @param node [Node] The node for which to fetch the configuration.
      # @param group [String] The group under which to look for the configuration.
      # @return [String] The contents of the configuration file, or 'node not found'.
      def fetch(node, group)
        repo, path = yield_repo_and_path(node, group)
        repo = Rugged::Repository.new repo
        index = repo.index
        index.read_tree repo.head.target.tree unless repo.empty?
        repo.read(index.get(path)[:oid]).data
      rescue StandardError
        'node not found'
      end

      # Retrieves the version history of a node's configuration.
      #
      # @param node [Node] The node for which to retrieve the version history.
      # @param group [String] The group of the node.
      # @return [Array] An array of hashes containing commit information, or 'node not found'.
      def version(node, group)
        repo, path = yield_repo_and_path(node, group)

        repo = Rugged::Repository.new repo
        walker = Rugged::Walker.new(repo)
        walker.sorting(Rugged::SORT_DATE)
        walker.push(repo.head.target.oid)
        i = -1
        tab = []
        walker.each do |commit|
          # @!visibility private
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

      # Retrieves the blob of a specific revision.
      #
      # @param node [Node] The node for which to get the blob.
      # @param group [String] The group of the node.
      # @param oid [String] The object ID of the revision.
      # @return [String] The content of the blob, or 'version not found'.
      def get_version(node, group, oid)
        repo, path = yield_repo_and_path(node, group)
        repo = Rugged::Repository.new repo
        repo.blob_at(oid, path).content
      rescue StandardError
        'version not found'
      end

      # Retrieves the diff between two revisions.
      #
      # @param node [Node] The node for which to get the diff.
      # @param group [String] The group of the node.
      # @param oid1 [String] The object ID of the first revision.
      # @param oid2 [String, nil] The object ID of the second revision, if available.
      # @return [Hash] A hash with the patch of the diff and statistics, or 'no diffs'.
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

      # Yields the repository and path for a given node and group.
      #
      # @param node [Node] The node for which to yield the repository and path.
      # @param group [String] The group of the node.
      # @return [Array] An array containing the repository and path.
      def yield_repo_and_path(node, group)
        repo, path = node.repo, node.name

        path = "#{group}/#{node.name}" if group && !group.empty? && @cfg.single_repo?

        [repo, path]
      end

      # Updates the repository with the given file and data.
      #
      # @param repo [String] The repository path.
      # @param file [String] The file to update.
      # @param data [String] The data to write to the file.
      # @return [void]
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

      # Updates the repository with the specified file and data.
      #
      # @param repo [Rugged::Repository] The repository instance.
      # @param file [String] The file to update.
      # @param data [String] The data to write to the file.
      # @return [void]
      def update_repo(repo, file, data)
        oid_old = repo.blob_at(repo.head.target_id, file) rescue nil
        return false if oid_old && (oid_old.content.b == data.b)

        oid = repo.write data, :blob
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
