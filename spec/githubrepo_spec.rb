require 'spec_helper'
require 'rugged'
require 'oxidized/hook/githubrepo'

describe Oxidized::Node do
  before(:each) do
    asetus = Asetus.new
    asetus.cfg.output.git.repo = 'foo.git'
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
