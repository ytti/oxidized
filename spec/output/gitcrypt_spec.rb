require_relative '../spec_helper'
require 'oxidized/output/gitcrypt'
require 'fileutils'
require 'tmpdir'

describe Oxidized::Output::GitCrypt do
  describe '#get_diff' do
    before do
      Oxidized.asetus = Asetus.new
      Oxidized.config.output.gitcrypt.single_repo = true
      @tmpdir = Dir.mktmpdir('oxidized-gitcrypt-spec')
      @repo = Git.init(@tmpdir)
      @repo.config('user.name', 'oxidized')
      @repo.config('user.email', 'ox@id.iz')
      @node1 = stub(repo: @tmpdir, name: 'node1')
      @git = Oxidized::Output::GitCrypt.new
      @git.stubs(:lock)
      @git.stubs(:unlock)
    end

    after do
      FileUtils.remove_entry(@tmpdir)
    end

    def commit_files(files)
      files.each do |path, data|
        FileUtils.mkdir_p(File.join(@tmpdir, File.dirname(path)))
        File.write(File.join(@tmpdir, path), data)
      end
      @repo.add(all: true)
      @repo.commit('update')
      @repo.object('HEAD').sha
    end

    it 'only returns the diff of the node when the commit contains several nodes' do
      oid1 = commit_files({ 'grp/node1' => "a\n", 'grp/node10' => "a\n", 'grp/node2' => "a\n" })
      oid2 = commit_files({ 'grp/node1' => "b\n", 'grp/node10' => "b\n", 'grp/node2' => "b\n" })

      [nil, oid1].each do |old|
        diff = @git.get_diff(@node1, 'grp', oid2, old)
        _(diff[:patch]).must_include 'grp/node1'
        _(diff[:patch]).wont_include 'grp/node10'
        _(diff[:patch]).wont_include 'grp/node2'
        _(diff[:stat]).must_equal [1, 1]
      end
    end

    it 'returns "no diffs" when the commit does not exist' do
      commit_files({ 'grp/node1' => "a\n" })
      _(@git.get_diff(@node1, 'grp', 'deadbeef' * 5, nil)).must_equal 'no diffs'
    end

    it 'returns "no diffs" when oid2 does not exist' do
      oid = commit_files({ 'grp/node1' => "a\n" })
      _(@git.get_diff(@node1, 'grp', oid, 'deadbeef' * 5)).must_equal 'no diffs'
    end
  end
end
