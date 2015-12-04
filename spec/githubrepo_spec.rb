require 'spec_helper'
require 'rugged'
require 'oxidized/hook/githubrepo'

describe Oxidized::Node do
  before(:each) do
    asetus = Asetus.new
    asetus.cfg.output.git.repo = 'foo.git'
    asetus.cfg.hooks.github_repo_hook.remote_repo = 'https://github.com/blah/blah.git'
    asetus.cfg.hooks.github_repo_hook.username = 'username'
    asetus.cfg.hooks.github_repo_hook.password = 'password'
    GithubRepo.any_instance.stubs(:cfg).returns(asetus.cfg.hooks.github_repo_hook)
    Oxidized.stubs(:asetus).returns(asetus)
    repo = mock()
    remote = mock()
    remote.expects(:url).returns('github.com/foo.git')
    remote.expects(:push).returns(true)
    repo.expects(:remotes).returns({'origin' => remote})
    repo.expects(:path).returns('foo.git')
    Rugged::Repository.expects(:new).with('foo.git').returns(repo)
  end

  describe "#run_hook" do
    it "will push to the remote repository" do
      gr = GithubRepo.new
      gr.run_hook(nil).must_equal true
    end
  end
end
