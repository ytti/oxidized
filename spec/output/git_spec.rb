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

  describe '::hash_list' do
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
      @repo.add_commit(['file3'], ['file1'], Time.new(2002), 'C0002')

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

      # Clean the persistent cache at the end of the test
      Oxidized::Output::Git.clear_cache
    end

    it 'returns the new commits in the right sequence' do
      skip 'not implemented yet'
      @repo.add_commit(%w[file1 file2], [], Time.new(2001), 'C0001')
      @repo.add_commit(['file3'], ['file1'], Time.new(2002), 'C0002')
      hashlist = Oxidized::Output::Git.hash_list('file1', '/tmp/o.git')
      _(hashlist.length).must_equal 2
      _(hashlist[0][:oid]).must_equal 'C0002'
      _(hashlist[1][:oid]).must_equal 'C0001'

      @repo.add_commit(['file3'], %w[file1 file2], Time.new(2003), 'C0003')
      hashlist = Oxidized::Output::Git.hash_list('file1', '/tmp/o.git')
      _(hashlist.length).must_equal 3
      _(hashlist[0][:oid]).must_equal 'C0003'
      _(hashlist[1][:oid]).must_equal 'C0002'
      _(hashlist[2][:oid]).must_equal 'C0001'
    end
  end

  describe '::version' do
    it 'works with single_repo=false' do
      skip 'no test yet'
    end
  end
end
