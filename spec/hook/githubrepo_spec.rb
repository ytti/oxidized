require_relative '../spec_helper'
require 'rugged'
require 'oxidized/hook/githubrepo'

describe GithubRepo do
  let(:credentials) { mock }
  let(:remote) { mock 'remote' }
  let(:remotes) { mock 'remotes' }
  let(:repo_head) { mock 'repo_head' }
  let(:repo) { mock 'repo' }
  let(:gr) { GithubRepo.new }
  let(:local_branch) { mock 'local_branch' }
  let(:remote_branch) { mock 'remote_branch' }
  let(:repo_branches) { mock 'repo_branches' }

  before do
    Oxidized.asetus = Asetus.new
    Oxidized.config.log = File::NULL
    Oxidized.setup_logger
    Oxidized.config.output.default = 'git'
  end

  describe '#validate_cfg!' do
    before do
      gr.expects(:respond_to?).with(:validate_cfg!).returns(false) # `cfg=` call
    end

    it 'raise a error when `remote_repo` is not configured' do
      Oxidized.config.hooks.github_repo_hook = { type: 'githubrepo' }
      gr.cfg = Oxidized.config.hooks.github_repo_hook
      _ { gr.validate_cfg! }.must_raise(KeyError)
    end
  end

  describe "#fetch_and_merge_remote" do
    before(:each) do
      Oxidized.config.hooks.github_repo_hook.remote_repo = 'git@github.com:username/foo.git'
      repo_head.expects(:name).returns('refs/heads/master').twice
      gr.cfg = Oxidized.config.hooks.github_repo_hook

      # Call in fetch
      repo.expects(:head).returns(repo_head)

      # Calls in remote_branch(repo)
      repo.expects(:head).returns(repo_head)
      repo.expects(:branches).returns(repo_branches).twice
      repo_branches.expects(:[]).with('refs/heads/master').returns(local_branch)
      local_branch.expects(:name).returns('master')
      repo_branches.expects(:[]).with('origin/master').returns(remote_branch)

      # For merge_analysis
      remote_branch.expects(:target_id).returns('111111')
    end

    it "should not try to merge when there is no need to" do
      # Fetch returns without having fetched objects
      repo.expects(:fetch).with('origin', ['refs/heads/master'], credentials: credentials).returns(Hash.new(0))

      # No need to merge
      repo.expects(:merge_analysis).with('111111').returns([:up_to_date])

      _(gr.fetch_and_merge_remote(repo, credentials)).must_be_nil
    end

    describe "when there is update considering conflicts" do
      let(:merge_index) { mock }

      before(:each) do
        # Fetch returns with having fetched objects
        repo.expects(:fetch).with('origin', ['refs/heads/master'], credentials: credentials).returns(total_deltas: 1)

        # SHA1 for merge - head and remote_branch
        repo.expects(:head).returns(repo_head)
        repo_head.expects(:target_id).returns('000000')
        remote_branch.expects(:target_id).returns('111111')

        # Need to merge
        repo.expects(:merge_analysis).with('111111').returns([:normal])

        # log message that we need to merge
        remote_branch.expects(:name).returns('origin/master')

        # try to merge
        repo.expects(:merge_commits).with('000000', '111111').returns(merge_index)
      end

      it "should not try merging when there's conflict" do
        merge_index.expects(:conflicts?).returns(true)
        Rugged::Commit.expects(:create).never
        _(gr.fetch_and_merge_remote(repo, credentials)).must_be_nil
      end

      it "should merge when there is no conflict" do
        merge_index.expects(:conflicts?).returns(false)

        # Mocks for Rugged::Commit.create
        repo.expects(:head).returns(repo_head)
        remote_branch.expects(:target).returns("their_target")
        remote_branch.expects(:name).returns("origin/master")
        repo_head.expects(:target).returns("our_target")
        merge_index.expects(:write_tree).with(repo).returns("tree")
        Rugged::Commit.expects(:create).with(repo,
                                             parents:    %w[our_target their_target],
                                             tree:       "tree",
                                             message:    "Merge remote-tracking branch 'origin/master'",
                                             update_ref: "HEAD").returns(1)
        _(gr.fetch_and_merge_remote(repo, credentials)).must_equal 1
      end
    end
  end

  describe "#run_hook" do
    let(:group) { nil }
    let(:ctx) { OpenStruct.new(node: node) }
    let(:node) do
      Oxidized::Node.new(ip: '127.0.0.1', group: group, model: 'junos', output: 'git')
    end

    before do
      Proc.expects(:new).returns(credentials)
      repo_head.expects(:name).twice.returns('refs/heads/master')
      repo.expects(:head).twice.returns(repo_head)
      repo.expects(:path).returns('/foo.git')
      repo.expects(:fetch).with('origin', ['refs/heads/master'], credentials: credentials).returns(Hash.new(0))
    end

    describe 'when there is only one repository and no groups' do
      before do
        Oxidized.config.output.git.repo = '/foo.git'
        remote.expects(:url).returns('https://github.com/username/foo.git')
        remote.expects(:push).with(['refs/heads/master'], credentials: credentials).returns(true)
        repo.expects(:remotes).returns('origin' => remote)
        Rugged::Repository.expects(:new).with('/foo.git').returns(repo)
      end

      it "will push to the remote repository using https" do
        skip "TODO TypeError: wrong argument type Mocha::Mock (expected Proc) when executing `gr.run_hook`"
        Oxidized.config.hooks.github_repo_hook.remote_repo = 'https://github.com/username/foo.git'
        Oxidized.config.hooks.github_repo_hook.username = 'username'
        Oxidized.config.hooks.github_repo_hook.password = 'password'
        Proc.expects(:new).returns(credentials)
        gr.cfg = Oxidized.config.hooks.github_repo_hook
        _(gr.run_hook(ctx)).must_equal true
      end

      it "will push to the remote repository using ssh" do
        skip "TODO TypeError: wrong argument type Mocha::Mock (expected Proc) when executing `gr.run_hook`"
        Oxidized.config.hooks.github_repo_hook.remote_repo = 'git@github.com:username/foo.git'
        Proc.expects(:new).returns(credentials)
        gr.cfg = Oxidized.config.hooks.github_repo_hook
        _(gr.run_hook(ctx)).must_equal true
      end
    end

    describe "when there are groups" do
      let(:group) { 'ggrroouupp' }

      before do
        Proc.expects(:new).returns(credentials)
        Rugged::Repository.expects(:new).with(repository).returns(repo)

        repo.expects(:remotes).twice.returns(remotes)
        remotes.expects(:[]).with('origin').returns(nil)
        remotes.expects(:create).with('origin', create_remote).returns(remote)
        remote.expects(:url).returns('url')
        remote.expects(:push).with(['refs/heads/master'], credentials: credentials).returns(true)
      end

      describe 'and there are several repositories' do
        let(:create_remote) { 'ggrroouupp#remote_repo' }
        let(:repository) { '/ggrroouupp.git' }

        before do
          Oxidized.config.output.git.repo.ggrroouupp = repository
          Oxidized.config.hooks.github_repo_hook.remote_repo.ggrroouupp = 'ggrroouupp#remote_repo'
        end

        it 'will push to the node group repository' do
          skip "TODO TypeError: wrong argument type Mocha::Mock (expected Proc) when executing `gr.run_hook`"
          gr.cfg = Oxidized.config.hooks.github_repo_hook
          _(gr.run_hook(ctx)).must_equal true
        end
      end

      describe 'and has a single repository' do
        let(:create_remote) { 'github_repo_hook#remote_repo' }
        let(:repository) { '/foo.git' }

        before do
          Oxidized.config.output.git.repo = repository
          Oxidized.config.hooks.github_repo_hook.remote_repo = 'github_repo_hook#remote_repo'
          Oxidized.config.output.git.single_repo = true
        end

        it 'will push to the correct repository' do
          skip "TODO TypeError: wrong argument type Mocha::Mock (expected Proc) when executing `gr.run_hook`"
          gr.cfg = Oxidized.config.hooks.github_repo_hook
          _(gr.run_hook(ctx)).must_equal true
        end
      end
    end
  end
end
