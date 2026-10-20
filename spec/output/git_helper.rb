require_relative '../spec_helper'
require 'oxidized/output/git'
require 'fileutils'
require 'tmpdir'

# Helpers to work with real Rugged repositories in a temporary directory
# (@tmpdir), which is removed after each test
module GitHelper
  def setup
    super
    @tmpdir = Dir.mktmpdir('oxidized-git-spec')
  end

  def teardown
    Oxidized::Output::Git.clear_cache
    FileUtils.remove_entry(@tmpdir)
    super
  end

  def init_repo(path)
    Rugged::Repository.init_at(path, :bare)
  end

  # Commits files ({ path => content }) on top of HEAD. A nil content
  # removes the file. Returns the oid of the new commit.
  def commit_files(repo, files, message: 'update', time: Time.now)
    index = Rugged::Index.new
    index.read_tree(repo.head.target.tree) unless repo.empty?
    files.each do |path, data|
      if data.nil?
        index.remove(path)
      else
        index.add(path: path, oid: repo.write(data, :blob), mode: 0o100644)
      end
    end
    signature = { name: 'oxidized', email: 'ox@id.iz', time: time }
    Rugged::Commit.create(repo,
                          tree:       index.write_tree(repo),
                          message:    message,
                          author:     signature,
                          committer:  signature,
                          parents:    repo.empty? ? [] : [repo.head.target],
                          update_ref: 'HEAD')
  end

  # Sorted list of the files in the tree of HEAD
  def head_files(repo)
    files = []
    repo.head.target.tree.walk_blobs { |root, entry| files << "#{root}#{entry[:name]}" }
    files.sort
  end
end
