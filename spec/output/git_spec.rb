require_relative 'git_helper'

describe Oxidized::Output::Git do
  describe '#yield_repo_and_path' do
    # Note that #yield_repo_and_path is private, so we can not call it directy
    # we use @git.send(:yield_repo_and_path, ...) to bypass the protection
    before do
      Oxidized.asetus = Asetus.new
      # Default value in most tests
      Oxidized.config.output.git.single_repo = true

      @mock_node = mock("Oxidized::Node")
      @mock_node.expects(:repo).returns('/tmp/oxidized.git')
      @mock_node.expects(:name).returns('switch-42')

      @git = Oxidized::Output::Git.new
    end

    it 'accepts group = nil' do
      result = @git.send(:yield_repo_and_path, @mock_node, nil)
      _(result).must_equal ['/tmp/oxidized.git', 'switch-42']
    end

    it 'ignores an empty group' do
      result = @git.send(:yield_repo_and_path, @mock_node, nil)
      _(result).must_equal ['/tmp/oxidized.git', 'switch-42']
    end

    it 'takes the group into accout when simple_repo=true' do
      # node.name will be needed a second time
      @mock_node.expects(:name).returns('switch-42')
      result = @git.send(:yield_repo_and_path, @mock_node, 'testgroup')
      _(result).must_equal ['/tmp/oxidized.git', 'testgroup/switch-42']
    end

    it 'ignores the group when simple_repo=false' do
      Oxidized.config.output.git.single_repo = false
      result = @git.send(:yield_repo_and_path, @mock_node, 'testgroup')
      _(result).must_equal ['/tmp/oxidized.git', 'switch-42']
    end
  end

  describe '.hash_list' do
    include GitHelper

    before do
      @repo_path = File.join(@tmpdir, 'oxidized.git')
      @repo = init_repo(@repo_path)
    end

    def oids(file)
      Oxidized::Output::Git.hash_list(file, @repo_path).map { |h| h[:oid] }
    end

    def messages
      Oxidized::Output::Git.hash_list('node1', @repo_path).map { |h| h[:message] }
    end

    it 'returns a list of hashes' do
      commit_files(@repo, { 'file1' => 'v1', 'file2' => 'v1' }, time: Time.new(2001))
      commit_files(@repo, { 'file2' => 'v2' }, time: Time.new(2002))
      oid = commit_files(@repo, { 'file3' => 'v1', 'file1' => 'v2' }, time: Time.new(2003))

      hashlist = Oxidized::Output::Git.hash_list('file1', @repo_path)
      _(hashlist.length).must_equal 2
      _(hashlist[0][:oid]).must_equal oid
      _(hashlist[0][:time]).must_equal Time.new(2003)
      _(hashlist[0][:date]).must_equal Time.new(2003).to_s
      _(hashlist[0][:message]).must_equal 'update'
      _(hashlist[0][:author][:name]).must_equal 'oxidized'
    end

    it 'ignores deleted files' do
      commit_files(@repo, { 'file1' => 'v1', 'file2' => 'v1' })
      commit_files(@repo, { 'file2' => nil })

      _(oids('file2').length).must_equal 1
    end

    it 'does not walk the logs twice when ran twice' do
      commit_files(@repo, { 'file1' => 'v1', 'file2' => 'v1' }, time: Time.new(2001))
      commit_files(@repo, { 'file3' => 'v1', 'file1' => 'v2' }, time: Time.new(2002))
      _(oids('file1').length).must_equal 2

      Rugged::Walker.expects(:new).never
      _(oids('file1').length).must_equal 2
    end

    it 'returns recent commits in the right order' do
      c1 = commit_files(@repo, { 'file1' => 'v1', 'file2' => 'v1' }, time: Time.new(2001))
      c2 = commit_files(@repo, { 'file3' => 'v1', 'file1' => 'v2' }, time: Time.new(2002))
      _(oids('file1')).must_equal [c2, c1]

      c3 = commit_files(@repo, { 'file3' => 'v2', 'file1' => 'v3', 'file2' => 'v2' }, time: Time.new(2003))
      c4 = commit_files(@repo, { 'file1' => 'v4' }, time: Time.new(2004))
      _(oids('file1')).must_equal [c4, c3, c2, c1]
      _(oids('file2')).must_equal [c3, c1]
    end

    it 'keeps all commits made within the same second in the right order' do
      time = Time.new(2024, 1, 1)
      commit_files(@repo, { 'node1' => 'v1' }, message: 'v1', time: time)
      _(messages).must_equal %w[v1]

      %w[v2 v3 v4 v5].each { |data| commit_files(@repo, { 'node1' => data }, message: data, time: time) }
      _(messages).must_equal %w[v5 v4 v3 v2 v1]
    end

    it 'rebuilds the cache when the history has been rewritten' do
      commit_files(@repo, { 'node1' => 'v1' }, message: 'v1')
      oid_v2 = commit_files(@repo, { 'node1' => 'v2' }, message: 'v2')
      commit_files(@repo, { 'node1' => 'v3' }, message: 'v3')
      _(messages).must_equal %w[v3 v2 v1]

      Oxidized::Output::Git.logger.expects(:warn)
                           .with(regexp_matches(/^update_cache: history of .* rewritten, rebuilding cache/))

      @repo.references.update('refs/heads/master', oid_v2)
      _(messages).must_equal %w[v2 v1]
    end

    it 'does not lose a commit made while walking the logs' do
      commit_files(@repo, { 'node1' => 'v1' }, message: 'v1')

      # Manipulated walker to simulate a worker committing during the walk
      walker = Rugged::Walker.new(@repo)
      test = self
      repo = @repo
      walker.define_singleton_method(:push) do |oid|
        super(oid)
        test.commit_files(repo, { 'node1' => 'v2' }, message: 'v2')
      end
      Rugged::Walker.expects(:new).returns(walker)

      # First call: v2 committed after HEAD was read
      _(messages).must_equal %w[v1]

      # Second call (with a normal walker) should include the commit made during the first call
      Rugged::Walker.unstub(:new)
      _(messages).must_equal %w[v2 v1]
    end
  end

  describe '#store and #fetch' do
    include GitHelper

    before do
      @repo_path = File.join(@tmpdir, 'oxidized.git')
      Oxidized.asetus = Asetus.new
      Oxidized.config.output.git.single_repo = true
      Oxidized.config.output.git.user = 'Oxidized'
      Oxidized.config.output.git.email = 'oxidized@example.com'
      Oxidized.config.output.git.repo = @repo_path
      @git = Oxidized::Output::Git.new
    end

    def store(node, data)
      outputs = Oxidized::Model::Outputs.new
      outputs << data
      @git.store(node, outputs, msg: "update #{node}")
    end

    it 'keeps changes merged into HEAD without updating the index (githubrepo hook)' do
      store('node1', "node1 v1\n")
      store('node2', "node2 v1\n")

      # Merge an upstream change like Hook::GithubRepo#fetch_and_merge_remote
      repo = Rugged::Repository.new(@repo_path)
      base = repo.head.target
      index = Rugged::Index.new
      index.read_tree(base.tree)
      index.add path: 'node2', oid: repo.write("node2 upstream\n", :blob), mode: 0o100644
      upstream = Rugged::Commit.create(repo, tree: index.write_tree(repo), message: 'upstream', parents: [base])
      merge_index = repo.merge_commits(base.oid, upstream)
      Rugged::Commit.create(repo,
                            parents:    [base, repo.lookup(upstream)],
                            tree:       merge_index.write_tree(repo),
                            message:    'merge',
                            update_ref: 'HEAD')

      node2 = stub(repo: @repo_path, name: 'node2')
      _(@git.fetch(node2, nil)).must_equal "node2 upstream\n"

      store('node1', "node1 v2\n")
      _(@git.fetch(node2, nil)).must_equal "node2 upstream\n"

      # The index on disk is kept in sync with HEAD for older Oxidized versions
      repo = Rugged::Repository.new(@repo_path)
      _(repo.index.write_tree(repo)).must_equal repo.head.target.tree_id
    end

    it 'works without an index file on disk (#3887)' do
      store('node1', "node1 v1\n")
      store('node2', "node2 v1\n")
      File.delete(File.join(@repo_path, 'index'))

      node2 = stub(repo: @repo_path, name: 'node2')
      _(@git.fetch(node2, nil)).must_equal "node2 v1\n"

      store('node1', "node1 v2\n")
      _(@git.fetch(node2, nil)).must_equal "node2 v1\n"
    end
  end

  describe '#version' do
    include GitHelper

    before do
      Oxidized.asetus = Asetus.new
    end

    it 'works with single_repo=false' do
      Oxidized.config.output.git.single_repo = false

      group1_path = File.join(@tmpdir, 'group1.git')
      repo_group1 = init_repo(group1_path)
      commit_files(repo_group1, { 'node1' => 'v1', 'node2' => 'v1' }, time: Time.new(2001))
      commit_files(repo_group1, { 'node1' => 'v2' }, time: Time.new(2002))

      group2_path = File.join(@tmpdir, 'group2.git')
      repo_group2 = init_repo(group2_path)
      commit_files(repo_group2, { 'node8' => 'v1', 'node9' => 'v1' }, time: Time.new(2008))
      commit_files(repo_group2, { 'node9' => 'v2' }, time: Time.new(2009))

      node1 = stub(repo: group1_path, name: 'node1')
      node8 = stub(repo: group2_path, name: 'node8')

      git = Oxidized::Output::Git.new
      _(git.version(node1, 'group1').length).must_equal 2
      _(git.version(node8, 'group2').length).must_equal 1
    end

    it 'works with single_repo=true' do
      Oxidized.config.output.git.single_repo = true

      repo_path = File.join(@tmpdir, 'oxidized.git')
      repo = init_repo(repo_path)
      commit_files(repo, { 'group1/node1' => 'v1', 'group1/node2' => 'v1' }, time: Time.new(2001))
      commit_files(repo, { 'group1/node1' => 'v2' }, time: Time.new(2002))
      commit_files(repo, { 'group2/node8' => 'v1', 'group2/node9' => 'v1' }, time: Time.new(2008))
      commit_files(repo, { 'group2/node9' => 'v2' }, time: Time.new(2009))

      node1 = stub(repo: repo_path, name: 'node1')
      node8 = stub(repo: repo_path, name: 'node8')

      git = Oxidized::Output::Git.new
      _(git.version(node1, 'group1').length).must_equal 2

      # The second call hits the cache, as HEAD did not change
      Rugged::Walker.expects(:new).never
      _(git.version(node8, 'group2').length).must_equal 1
    end

    it 'returns "node not found" when the repository does not exist' do
      node = stub(repo: File.join(@tmpdir, 'missing.git'), name: 'node1')
      _(Oxidized::Output::Git.new.version(node, nil)).must_equal 'node not found'
    end
  end

  describe '.clean_obsolete_nodes' do
    include GitHelper

    before do
      @repo_path = File.join(@tmpdir, 'oxidized.git')
      Oxidized.asetus = Asetus.new

      Oxidized.config.output.git.user = 'Oxidized'
      Oxidized.config.output.git.email = 'oxidized@example.com'
      Oxidized.config.output.git.repo = @repo_path
      Oxidized.config.output.git.single_repo = true

      @opts = {
        input:  'ssh',
        output: 'git',
        model:  'ios'
      }
    end

    def all_files
      %w[node1 node2 node3 gr1/node11 gr1/node12 gr1/gr2/node121 gr1/gr2/node122]
    end

    def create_repo_with_all_files
      repo = init_repo(@repo_path)
      commit_files(repo, all_files.to_h { |f| [f, "#{f} config\n"] })
      repo
    end

    def active_nodes
      nodes = %w[node1 node2].map { |e| Oxidized::Node.new(@opts.merge(name: e)) }
      nodes += %w[node11].map { |e| Oxidized::Node.new(@opts.merge(name: e, group: 'gr1')) }
      nodes + %w[node121].map { |e| Oxidized::Node.new(@opts.merge(name: e, group: 'gr1/gr2')) }
    end

    it "does nothing when the repo dir doesn't exists" do
      Oxidized::Output::Git.clean_obsolete_nodes(active_nodes)

      _(File.exist?(@repo_path)).must_equal false
    end

    it "does nothing when the repo is empty" do
      init_repo(@repo_path)

      Oxidized::Output::Git.clean_obsolete_nodes(active_nodes)

      _(Rugged::Repository.new(@repo_path).empty?).must_equal true
    end

    it "does nothing without single_repo = true" do
      Oxidized.config.output.git.single_repo = false
      head = create_repo_with_all_files.head.target_id
      Oxidized::Output::Git.logger.expects(:warn)
                           .with("clean_obsolete_nodes is not implemented for " \
                                 "multiple git repositories")

      Oxidized::Output::Git.clean_obsolete_nodes(active_nodes)

      _(Rugged::Repository.new(@repo_path).head.target_id).must_equal head
    end

    it "does nothing when type_as_directory = true" do
      Oxidized.config.output.git.type_as_directory = true
      head = create_repo_with_all_files.head.target_id
      Oxidized::Output::Git.logger.expects(:warn)
                           .with("clean_obsolete_nodes is not implemented for output " \
                                 "types as a directory within the git repository")

      Oxidized::Output::Git.clean_obsolete_nodes(active_nodes)

      _(Rugged::Repository.new(@repo_path).head.target_id).must_equal head
    end

    it "removes obsolete configuration files" do
      old_head = create_repo_with_all_files.head.target_id
      Oxidized::Output::Git.logger.expects(:info)
                           .with("clean_obsolete_nodes: removing 3 obsolete configs")

      Oxidized::Output::Git.clean_obsolete_nodes(active_nodes)

      repo = Rugged::Repository.new(@repo_path)
      _(head_files(repo)).must_equal %w[gr1/gr2/node121 gr1/node11 node1 node2]
      commit = repo.head.target
      _(commit.message).must_equal 'Removing 3 obsolete configs'
      _(commit.parent_ids).must_equal [old_head]
      _(commit.author[:name]).must_equal 'Oxidized'
      _(commit.author[:email]).must_equal 'oxidized@example.com'
      # The index on disk is kept in sync with HEAD
      _(repo.index.write_tree(repo)).must_equal commit.tree_id
    end

    it "does nothing if there is nothing to delete" do
      repo = init_repo(@repo_path)
      head = commit_files(repo, { 'node1' => "node1\n", 'node2' => "node2\n" })
      nodes = %w[node1 node2].map { |e| Oxidized::Node.new(@opts.merge(name: e)) }

      Oxidized::Output::Git.clean_obsolete_nodes(nodes)

      _(Rugged::Repository.new(@repo_path).head.target_id).must_equal head
    end
  end
end
