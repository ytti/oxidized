require 'spec_helper'
require 'rugged'
require 'oxidized/hook/githubrepo'

describe Oxidized::Node do
  let(:credentials) { mock() }
  let(:remote) { mock() }
  let(:repo_head) { mock() }
  let(:repo) { mock() }
  let(:gr) { GithubRepo.new }

  before(:each) do
    Oxidized.asetus = Asetus.new
    Oxidized.config.output.git.repo = 'foo.git'
    Oxidized.setup_logger
  end

  describe "#fetch_and_merge_remote" do
    before(:each) do
      Oxidized.config.hooks.github_repo_hook.remote_repo = 'git@github.com:username/foo.git'
      Rugged::Credentials::SshKeyFromAgent.expects(:new).with(username: 'git').returns(credentials)
      repo_head.expects(:name).returns('refs/heads/master')
      gr.cfg = Oxidized.config.hooks.github_repo_hook
    end

    it "should not try to merge when there is no update in remote branch" do
      repo.expects(:fetch).with('origin', ['refs/heads/master'], credentials: credentials).returns(Hash.new(0))
      repo.expects(:branches).never
      repo.expects(:head).returns(repo_head)
      gr.fetch_and_merge_remote(repo).must_equal nil
    end
    describe "when there is update considering conflicts" do
      let(:merge_index) { mock() }
      let(:their_branch) { mock() }

      before(:each) do
        repo.expects(:fetch).with('origin', ['refs/heads/master'], credentials: credentials).returns({total_deltas: 1})
        their_branch.expects(:target_id).returns(1)
        repo_head.expects(:target_id).returns(2)
        repo.expects(:merge_commits).with(2, 1).returns(merge_index)
        repo.expects(:branches).returns({"origin/master" => their_branch})
      end

      it "should not try merging when there's conflict" do
        repo.expects(:head).twice.returns(repo_head)
        their_branch.expects(:name).returns("origin/master")
        merge_index.expects(:conflicts?).returns(true)
        Rugged::Commit.expects(:create).never
        gr.fetch_and_merge_remote(repo).must_equal nil
      end

      it "should merge when there is no conflict" do
        repo.expects(:head).times(3).returns(repo_head)
        their_branch.expects(:target).returns("their_target")
        their_branch.expects(:name).twice.returns("origin/master")
        repo_head.expects(:target).returns("our_target")
        merge_index.expects(:write_tree).with(repo).returns("tree")
        merge_index.expects(:conflicts?).returns(false)
        Rugged::Commit.expects(:create).with(repo, {
          parents: ["our_target", "their_target"],
          tree: "tree",
          message: "Merge remote-tracking branch 'origin/master'",
          update_ref: "HEAD"
        }).returns(1)
        gr.fetch_and_merge_remote(repo).must_equal 1
      end
    end
  end

  describe "#run_hook" do
    before(:each) do
      remote.expects(:url).returns('https://github.com/username/foo.git')
      remote.expects(:push).with(['refs/heads/master'], credentials: credentials).returns(true)
      repo_head.expects(:name).twice.returns('refs/heads/master')
      repo.expects(:head).twice.returns(repo_head)
      repo.expects(:path).returns('foo.git')
      repo.expects(:remotes).returns({'origin' => remote})
      repo.expects(:fetch).with('origin', ['refs/heads/master'], credentials: credentials).returns(Hash.new(0))
      Rugged::Repository.expects(:new).with('foo.git').returns(repo)
    end

    it "will push to the remote repository using https" do
      Oxidized.config.hooks.github_repo_hook.remote_repo = 'https://github.com/username/foo.git'
      Oxidized.config.hooks.github_repo_hook.username = 'username'
      Oxidized.config.hooks.github_repo_hook.password = 'password'
      Rugged::Credentials::UserPassword.expects(:new).with(username: 'username', password: 'password').returns(credentials)
      gr.cfg = Oxidized.config.hooks.github_repo_hook
      gr.run_hook(nil).must_equal true
    end

    it "will push to the remote repository using ssh" do
      Oxidized.config.hooks.github_repo_hook.remote_repo = 'git@github.com:username/foo.git'
      Rugged::Credentials::SshKeyFromAgent.expects(:new).with(username: 'git').returns(credentials)
      gr.cfg = Oxidized.config.hooks.github_repo_hook
      gr.run_hook(nil).must_equal true
    end
  end
end
