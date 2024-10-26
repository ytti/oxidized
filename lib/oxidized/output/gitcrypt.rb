module Oxidized
  module Output
    # Handles GitCrypt-based output for storing encrypted configurations in Oxidized.
    #
    # This class extends the Output module and provides methods for
    # storing, fetching, and managing configurations using a Git repository with GitCrypt encryption.
    class GitCrypt < Output
      using Refinements
      require '../error/gitcrypterror'

      # @!attribute [rw] commitref
      # @return [String] The commit reference of the latest commit.
      attr_reader :commitref

      # Initializes the GitCrypt output instance.
      #
      # @return [void]
      def initialize
        super
        @cfg = Oxidized.config.output.gitcrypt
        @gitcrypt_cmd = "/usr/bin/git-crypt"
        @gitcrypt_init = @gitcrypt_cmd + " init"
        @gitcrypt_unlock = @gitcrypt_cmd + " unlock"
        @gitcrypt_lock = @gitcrypt_cmd + " lock"
        @gitcrypt_adduser = @gitcrypt_cmd + " add-gpg-user --trusted "
      end

      # Sets up the GitCrypt configuration for output.
      #
      # @raise [NoConfig] if no output GitCrypt configuration is provided.
      # @return [void]
      def setup
        if @cfg.empty?
          Oxidized.asetus.user.output.gitcrypt.user  = 'Oxidized'
          Oxidized.asetus.user.output.gitcrypt.email = 'o@example.com'
          Oxidized.asetus.user.output.gitcrypt.repo = File.join(Config::ROOT, 'oxidized.git')
          Oxidized.asetus.save :user
          raise Error::NoConfig, "no output git config, edit #{Oxidized::Config.configfile}"
        end

        if @cfg.repo.respond_to?(:each)
          @cfg.repo.each do |group, repo|
            @cfg.repo["#{group}="] = File.expand_path repo
          end
        else
          @cfg.repo = File.expand_path @cfg.repo
        end
      end

      # Initializes GitCrypt in the specified repository and adds users.
      #
      # @param repo [Git::Base] The Git repository to initialize GitCrypt in.
      # @return [void]
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

      # Locks the GitCrypt repository.
      #
      # @param repo [Git::Base] The Git repository to lock.
      # @return [void]
      def lock(repo)
        repo.chdir do
          system(@gitcrypt_lock)
        end
      end

      # Unlocks the GitCrypt repository.
      #
      # @param repo [Git::Base] The Git repository to unlock.
      # @return [void]
      def unlock(repo)
        repo.chdir do
          system(@gitcrypt_unlock)
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
        repo = Git.open repo
        unlock repo
        index = repo.index
        # @!visibility private
        # Empty repo ?
        raise 'Empty git repo' if File.exist?(index.path)

        File.read path
        lock repo
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

      # Retrieves the blob of a specific revision.
      #
      # @param node [Node] The node for which to get the blob.
      # @param group [String] The group of the node.
      # @param oid [String] The object ID of the revision.
      # @return [String] The content of the blob, or 'version not found'.
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

      # Retrieves the diff between two revisions.
      #
      # @param node [Node] The node for which to get the diff.
      # @param group [String] The group of the node.
      # @param oid1 [String] The object ID of the first revision.
      # @param oid2 [String, nil] The object ID of the second revision, if available.
      # @return [Hash] A hash with the patch of the diff and statistics, or 'no diffs'.
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

      # Yields the repository and path for a given node and group.
      #
      # @param node [Node] The node for which to yield the repository and path.
      # @param group [String] The group of the node.
      # @return [Array] An array containing the repository and path.
      def yield_repo_and_path(node, group)
        repo, path = node.repo, node.name

        path = "#{group}/#{node.name}" if group && @cfg.single_repo?

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
          update_repo repo, file, data, @msg, @user, @email
        rescue Git::GitExecuteError, ArgumentError => e
          Oxidized.logger.debug "open_error #{e} #{file}"
          begin
            grepo = Git.init repo
            crypt_init grepo
          rescue StandardError => create_error
            raise Error::GitCryptError, "first '#{e.message}' was raised while opening git repo, then '#{create_error.message}' was while trying to create git repo"
          end
          retry
        end
      end

      # Updates the repository with changes and commits them.
      #
      # @param repo [String] Path to the Git repository.
      # @param file [String] Path to the file being updated.
      # @param data [String] Data to be written to the file.
      # @param msg [String] Commit message.
      # @param user [String] Git user name.
      # @param email [String] Git user email.
      # @return [Boolean] True if the commit was successful, otherwise false.
      def update_repo(repo, file, data, msg, user, email)
        grepo = Git.open repo
        grepo.config('user.name', user)
        grepo.config('user.email', email)
        grepo.chdir do
          unlock grepo
          File.write(file, data)
          grepo.add(file)
          if grepo.status[file].nil? || !grepo.status[file].type.nil?
            grepo.commit(msg)
            @commitref = grepo.log(1).first.objectish
            true
          end
          lock grepo
        end
      end
    end
  end
end
