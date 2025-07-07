require_relative 'git_helper'

describe Oxidized::Output::Git do
  describe '#yield_repo_and_path' do
    # Note that #yield_repo_and_path is private, so we can not call it directy
    # we use @git.send(:yield_repo_and_path, ...) to bypass the protection
    before do
      Oxidized.asetus = Asetus.new
      # Default value in most tests
      Oxidized.config.output.git.single_repo = true

      @mock_node = Minitest::Mock.new
      @mock_node.expect(:repo, '/tmp/oxidized.git')
      @mock_node.expect(:name, 'switch-42')

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
      @mock_node.expect(:name, 'switch-42')
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
    before do
      @repo = RepoMock.new
      Rugged::Repository.stubs(:new).returns(@repo)
      walker = WalkerMock.new(@repo)
      Rugged::Walker.stubs(:new).returns(walker)
    end

    after do
      # Clean the persistent cache at the end of the test
      Oxidized::Output::Git.clear_cache
    end

    it 'returns a list of hashes' do
      @repo.add_commit(%w[file1 file2], [], Time.new(2001), 'C0001')
      @repo.add_commit([], ['file2'], Time.new(2002), 'C0002')
      @repo.add_commit(['file3'], ['file1'], Time.new(2003), 'C0003')

      hashlist = Oxidized::Output::Git.hash_list('file1', '/tmp/o.git')
      _(hashlist.length).must_equal 2
    end

    it 'does not walk the logs twice when ran twice' do
      @repo.add_commit(%w[file1 file2], [], Time.new(2001), 'C0001')
      @repo.add_commit(['file3'], ['file1'], Time.new(2002), 'C0002')

      hashlist = Oxidized::Output::Git.hash_list('file1', '/tmp/o.git')
      _(hashlist.length).must_equal 2

      CommitMock.any_instance.expects(:diff).never
      hashlist = Oxidized::Output::Git.hash_list('file1', '/tmp/o.git')
      _(hashlist.length).must_equal 2
    end

    it 'returns recent commits in the right order' do
      @repo.add_commit(%w[file1 file2], [], Time.new(2001), 'C0001')
      @repo.add_commit(['file3'], ['file1'], Time.new(2002), 'C0002')
      hashlist = Oxidized::Output::Git.hash_list('file1', '/tmp/o.git')
      _(hashlist.length).must_equal 2
      _(hashlist[0][:oid]).must_equal 'C0002'
      _(hashlist[1][:oid]).must_equal 'C0001'

      @repo.add_commit(['file3'], %w[file1 file2], Time.new(2003), 'C0003')
      @repo.add_commit([], %w[file1], Time.new(2004), 'C0004')
      hashlist = Oxidized::Output::Git.hash_list('file1', '/tmp/o.git')

      _(hashlist.length).must_equal 4
      _(hashlist[0][:oid]).must_equal 'C0004'
      _(hashlist[1][:oid]).must_equal 'C0003'
      _(hashlist[2][:oid]).must_equal 'C0002'
      _(hashlist[3][:oid]).must_equal 'C0001'
    end
  end

  describe '#version' do
    after do
      # Clean the persistent cache at the end of the test
      Oxidized::Output::Git.clear_cache
    end

    it 'works with single_repo=false' do
      Oxidized.asetus = Asetus.new
      Oxidized.config.output.git.single_repo = false

      @repo_group1 = RepoMock.new
      @repo_group1.add_commit(%w[node1 node2], [], Time.new(2001), 'C0001')
      @repo_group1.add_commit([], ['node1'], Time.new(2002), 'C0002')
      Rugged::Repository.expects(:new).with('/tmp/group1.git').returns(@repo_group1)
      walker = WalkerMock.new(@repo_group1)
      Rugged::Walker.expects(:new).with(@repo_group1).returns(walker)
      @mock_node1 = mock('Oxidized::Node')
      @mock_node1.expects(:repo).returns('/tmp/group1.git')
      @mock_node1.expects(:name).returns('node1')

      @repo_group2 = RepoMock.new
      @repo_group2.add_commit(%w[node8 node9], [], Time.new(2008), 'C0008')
      @repo_group2.add_commit([], ['node9'], Time.new(2009), 'C0009')
      Rugged::Repository.expects(:new).with('/tmp/group2.git').returns(@repo_group2)
      walker = WalkerMock.new(@repo_group2)
      Rugged::Walker.expects(:new).with(@repo_group2).returns(walker)
      @mock_node8 = mock('Oxidized::Node')
      @mock_node8.expects(:repo).returns('/tmp/group2.git')
      @mock_node8.expects(:name).returns('node8')

      git = Oxidized::Output::Git.new

      version_group1_node1 = git.version @mock_node1, 'group1'
      _(version_group1_node1.length).must_equal 2

      version_group2_node8 = git.version @mock_node8, 'group2'
      _(version_group2_node8.length).must_equal 1
    end

    it 'works with single_repo=true' do
      Oxidized.asetus = Asetus.new
      Oxidized.config.output.git.single_repo = true

      @repo = RepoMock.new
      @repo.add_commit(%w[group1/node1 group1/node2],
                       [], Time.new(2001), 'C0001')
      @repo.add_commit([], ['group1/node1'], Time.new(2002), 'C0002')
      @repo.add_commit(%w[group2/node8 group2/node9],
                       [], Time.new(2008), 'C0008')
      @repo.add_commit([], ['group2/node9'], Time.new(2009), 'C0009')

      Rugged::Repository.expects(:new).with('/tmp/oxidized.git').returns(@repo).twice
      walker = WalkerMock.new(@repo)
      Rugged::Walker.expects(:new).with(@repo).returns(walker).twice
      @mock_node1 = mock('Oxidized::Node')
      @mock_node1.expects(:repo).returns('/tmp/oxidized.git')
      @mock_node1.expects(:name).returns('node1').twice

      @mock_node8 = mock('Oxidized::Node')
      @mock_node8.expects(:repo).returns('/tmp/oxidized.git')
      @mock_node8.expects(:name).returns('node8').twice

      git = Oxidized::Output::Git.new

      version_group1_node1 = git.version @mock_node1, 'group1'
      _(version_group1_node1.length).must_equal 2

      version_group2_node8 = git.version @mock_node8, 'group2'
      _(version_group2_node8.length).must_equal 1
    end
  end

  describe '.clean_obsolete_nodes' do
    before do
      Oxidized.asetus = Asetus.new

      Oxidized.config.output.git.user = 'Oxidized'
      Oxidized.config.output.git.email = 'oxidized@example.com'
      Oxidized.config.output.git.repo = '/gitrepo'

      @opts = {
        input:  'ssh',
        output: 'git',
        model:  'ios'
      }
    end

    it "does nothing when the repo dir doesn't exists" do
      Oxidized.config.output.git.single_repo = true
      File.expects(:directory?).with('/gitrepo').returns(false)
      Rugged::Repository.expects(:new).never

      Oxidized::Output::Git.clean_obsolete_nodes([])
    end
    it "does nothing when the repo is empty" do
      Oxidized.config.output.git.single_repo = true
      File.expects(:directory?).with('/gitrepo').returns(true)
      mock_repo = mock('Rugged::Repository')
      Rugged::Repository.expects(:new).returns(mock_repo)
      mock_repo.expects(:empty?).returns(true)

      Oxidized::Output::Git.clean_obsolete_nodes([])
    end

    it "does nothing without single_repo = true" do
      Rugged::Repository.expects(:new).never
      Oxidized::Output::Git.logger.expects(:warn)
                           .with("clean_obsolete_nodes is not implemented for " \
                                 "multiple git repositories")

      Oxidized::Output::Git.clean_obsolete_nodes([])
    end

    it "does nothing when type_as_directory = true" do
      Oxidized.config.output.git.single_repo = true
      Oxidized.config.output.git.type_as_directory = true
      Rugged::Repository.expects(:new).never
      Oxidized::Output::Git.logger.expects(:warn)
                           .with("clean_obsolete_nodes is not implemented for output " \
                                 "types as a directory within the git repository")

      Oxidized::Output::Git.clean_obsolete_nodes([])
    end

    it "removes obsolete configuration files" do
      Oxidized.config.output.git.single_repo = true
      File.expects(:directory?).with('/gitrepo').returns(true)

      mock_repo = mock('Rugged::Repository')
      Rugged::Repository.expects(:new).returns(mock_repo)
      mock_repo.expects(:empty?).returns(false)

      nodes = %w[node1 node2].map { |e| Oxidized::Node.new(@opts.merge(name: e)) }
      nodes += %w[node11].map { |e| Oxidized::Node.new(@opts.merge(name: e, group: 'gr1')) }
      nodes += %w[node121].map { |e| Oxidized::Node.new(@opts.merge(name: e, group: 'gr1/gr2')) }

      mock_tree = mock('Tree')
      mock_repo.expects(:last_commit).returns(stub(tree: mock_tree))

      mock_tree.expects(:walk_blobs).multiple_yields(
        ['', { name: 'node1' }],
        ['', { name: 'node2' }],
        ['', { name: 'node3' }],
        ['gr1', { name: 'node11' }],
        ['gr1', { name: 'node12' }],
        ['gr1/gr2', { name: 'node121' }],
        ['gr1/gr2', { name: 'node122' }]
      )

      mock_index = mock('Index')
      mock_repo.expects(:index).returns(mock_index)
      mock_index.expects(:remove).with('node3')
      mock_index.expects(:remove).with('gr1/node12')
      mock_index.expects(:remove).with('gr1/gr2/node122')

      mock_repo.expects(:config).twice.returns({})
      mock_index.expects(:write_tree).returns('tree_sha')
      mock_repo.expects(:head).returns(stub(target: 'head_sha'))

      Rugged::Commit.expects(:create).with(
        mock_repo,
        message:    includes('Removing 3 obsolete configs'),
        tree:       'tree_sha',
        parents:    ['head_sha'],
        update_ref: 'HEAD'
      )
      Oxidized::Output::Git.logger.expects(:info)
                           .with("clean_obsolete_nodes: removing 3 obsolete configs")

      mock_index.expects(:write)

      Oxidized::Output::Git.clean_obsolete_nodes(nodes)
    end

    it "does nothing if there is nothing to delete" do
      Oxidized.config.output.git.single_repo = true
      File.expects(:directory?).with('/gitrepo').returns(true)

      mock_repo = mock('Rugged::Repository')
      Rugged::Repository.expects(:new).returns(mock_repo)
      mock_repo.expects(:empty?).returns(false)

      nodes = %w[node1 node2].map { |e| Oxidized::Node.new(@opts.merge(name: e)) }

      mock_tree = mock('Tree')
      mock_repo.expects(:last_commit).returns(stub(tree: mock_tree))

      mock_tree.expects(:walk_blobs).multiple_yields(
        ['', { name: 'node1' }],
        ['', { name: 'node2' }]
      )

      mock_repo.expects(:index).never
      Rugged::Commit.expects(:create).never

      Oxidized::Output::Git.clean_obsolete_nodes(nodes)
    end
  end
end
