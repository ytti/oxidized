require_relative '../spec_helper'
require 'oxidized/output/git'

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
end
