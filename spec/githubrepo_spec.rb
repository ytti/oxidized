require 'spec_helper'
require 'rugged'
require 'oxidized/hook/githubrepo'

describe Oxidized::Node do
  before(:each) do
    Oxidized.asetus = Asetus.new
    Oxidized.config.output.git.repo = 'foo.git'
    Oxidized.setup_logger

    @credentials = mock()

    remote = mock()
    remote.expects(:url).returns('https://github.com/username/foo.git')
    remote.expects(:push).with(['refs/heads/master'], credentials: @credentials).returns(true)

    repo_head = mock()
    repo_head.expects(:name).twice.returns('refs/heads/master')

    repo = mock()
    repo.expects(:path).returns('foo.git')
    repo.expects(:remotes).returns({'origin' => remote})
    repo.expects(:head).twice.returns(repo_head)
    repo.expects(:fetch).with('origin', ['refs/heads/master'], credentials: @credentials).returns(true)
    repo.expects(:branches).returns({})

    Rugged::Repository.expects(:new).with('foo.git').returns(repo)
  end

  describe "#run_hook" do
    it "will push to the remote repository using https" do
      Oxidized.config.hooks.github_repo_hook.remote_repo = 'https://github.com/username/foo.git'
      Oxidized.config.hooks.github_repo_hook.username = 'username'
      Oxidized.config.hooks.github_repo_hook.password = 'password'

      Rugged::Credentials::UserPassword.expects(:new).with(username: 'username', password: 'password').returns(@credentials)

      gr = GithubRepo.new
      gr.cfg = Oxidized.config.hooks.github_repo_hook

      gr.run_hook(nil).must_equal true
    end

    it "will push to the remote repository using ssh" do
      Oxidized.config.hooks.github_repo_hook.remote_repo = 'git@github.com:username/foo.git'

      Rugged::Credentials::SshKeyFromAgent.expects(:new).with(username: 'git').returns(@credentials)

      gr = GithubRepo.new
      gr.cfg = Oxidized.config.hooks.github_repo_hook

      gr.run_hook(nil).must_equal true
    end
  end
end
