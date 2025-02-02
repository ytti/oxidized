require 'simplecov'
require 'minitest/autorun'
require 'mocha/minitest'

require 'oxidized'
require 'oxidized/output/git'

Oxidized.mgr = Oxidized::Manager.new

class RepoMock
  attr_reader :commits, :head

  def initialize
    @commits = []
  end

  HeadMock = Struct.new(:target)
  TargetMock = Struct.new(:oid)

  def add_commit(added_files, modified_files, time, oid)
    @commits.append CommitMock.new(added_files, modified_files, time, oid)

    # #head.target.oid
    @head = HeadMock.new(TargetMock.new(oid))
  end
end

class CommitMock
  attr_reader :oid, :time, :author, :message, :diff,
              :added_files, :modified_files

  def initialize(added_files, modified_files, time, oid)
    @added_files = added_files
    @modified_files = modified_files
    @time = time
    @oid = oid
    @author =  { email: 'ox@id.iz', time: time, name: 'oxidized' }
    @message = "Commit ##{oid}"
    deltas = added_files.map do |file|
      DeltaMock.new(file, :added)
    end
    deltas += modified_files.map do |file|
      DeltaMock.new(file, :modified)
    end
    @diff = DiffMock.new deltas
  end
end

class DiffMock
  def initialize(deltas)
    @deltas = deltas
  end

  def each_delta(&)
    @deltas.each(&)
  end
end

class DeltaMock
  attr_reader :new_file

  def initialize(filename, status)
    @new_file = { path: filename }
    @status = status
  end

  def added?
    @status == :added
  end

  def modified?
    @status == :modified
  end
end

class WalkerMock
  def initialize(repo)
    @repo = repo
  end

  def sorting(*); end

  def push(*); end

  def each(&)
    @repo.commits.reverse_each(&)
  end
end
