module Oxidized
class Git < Output
  class GitError < OxidizedError; end
  begin
    require 'rugged'
  rescue LoadError
    raise OxidizedError, 'rugged not found: sudo gem install rugged'
  end

  attr_reader :commitref

  def initialize
    @cfg = Oxidized.config.output.git
  end

  def setup
    if @cfg.empty?
      Oxidized.asetus.user.output.git.user  = 'Oxidized'
      Oxidized.asetus.user.output.git.email = 'o@example.com'
      Oxidized.asetus.user.output.git.repo  =  File.join(Config::Root, 'oxidized.git')
      Oxidized.asetus.save :user
      raise NoConfig, 'no output git config, edit ~/.config/oxidized/config'
    end

    if @cfg.repo.respond_to?(:each)
      @cfg.repo.each do |group, repo|
        @cfg.repo["#{group}="] = File.expand_path repo
      end
    else
      @cfg.repo = File.expand_path @cfg.repo
    end
  end

  def store file, outputs, opt={}
    @msg   = opt[:msg]
    @user  = (opt[:user]  or @cfg.user)
    @email = (opt[:email] or @cfg.email)
    @opt   = opt
    @commitref = nil
    repo   = @cfg.repo

    outputs.types.each do |type|
      type_cfg = ''
      type_repo = File.join(File.dirname(repo), type + '.git')
      outputs.type(type).each do |output|
        (type_cfg << output; next) if not output.name
        type_file = file + '--' + output.name
        if @cfg.type_as_directory?
          type_file = type + '/' + type_file
          type_repo = repo
        end
        update type_repo, type_file, output
      end
      update type_repo, file, type_cfg
    end

    update repo, file, outputs.to_cfg
  end


  def fetch node, group
    begin
      repo, path = yield_repo_and_path(node, group)
      repo = Rugged::Repository.new repo
      index = repo.index
      index.read_tree repo.head.target.tree unless repo.empty?
      repo.read(index.get(path)[:oid]).data
    rescue
      'node not found'
    end
  end

    # give a hash of all oid revision for the given node, and the date of the commit
    def version node, group
      begin
        repo, path = yield_repo_and_path(node, group)

        repo = Rugged::Repository.new repo
        walker = Rugged::Walker.new(repo)
        walker.sorting(Rugged::SORT_DATE)
        walker.push(repo.head.target)
        i = -1
        tab  = []
        walker.each do |commit|
          if commit.diff(paths: [path]).size > 0
            hash = {}
            hash[:date] = commit.time.to_s
            hash[:oid] = commit.oid
            hash[:author] = commit.author
            hash[:message] = commit.message
            tab[i += 1] = hash
          end
        end
        walker.reset
        tab
      rescue
        'node not found'
      end
    end

    #give the blob of a specific revision
    def get_version node, group, oid
      begin
        repo, path = yield_repo_and_path(node, group)
        repo = Rugged::Repository.new repo
        repo.blob_at(oid,path).content
      rescue
        'version not found'
      end
    end

    #give a hash with the patch of a diff between 2 revision and the stats (added and deleted lines)
    def get_diff node, group, oid1, oid2
      begin
        diff_commits = nil
        repo, _ = yield_repo_and_path(node, group)
        repo = Rugged::Repository.new repo
        commit = repo.lookup(oid1)

        if oid2
          commit_old = repo.lookup(oid2)
          diff = repo.diff(commit_old, commit)
          diff.each do |patch|
            if /#{node.name}\s+/.match(patch.to_s.lines.first)
              diff_commits = {:patch => patch.to_s, :stat => patch.stat}
              break
            end
          end
        else
          stat = commit.parents[0].diff(commit).stat
          stat = [stat[1],stat[2]]
          patch = commit.parents[0].diff(commit).patch
          diff_commits = {:patch => patch, :stat => stat}
        end

        diff_commits
      rescue
        'no diffs'
      end
    end

  private

  def yield_repo_and_path(node, group)
    repo, path = node.repo, node.name

    if group and @cfg.single_repo?
      path = "#{group}/#{node.name}"
    end

    if group and @cfg.individual_repo?
      path = "#{node.name}"
    end
    [repo, path]
  end

  def update repo, file, data
    return if data.empty?

    if @opt[:group]
      if @cfg.single_repo?
        file = File.join @opt[:group], file
      else
        repo = if repo.is_a?(::String)
                 if(@cfg.individual_repo?)
                   File.join File.dirname(repo), @opt[:group], @opt[:name] + '.git'
                 else
                   File.join File.dirname(repo), @opt[:group] + '.git'
                 end
               else
                 repo[@opt[:group]]
               end
      end
    elsif(@cfg.individual_repo?)
      repo = File.join File.dirname(repo), '/default/', @opt[:name] + '.git'
    end

    begin
      repo = Rugged::Repository.new repo
      update_repo repo, file, data, @msg, @user, @email
    rescue Rugged::OSError, Rugged::RepositoryError => open_error
      begin
        Rugged::Repository.init_at repo, :bare
      rescue => create_error
        raise GitError, "first '#{open_error.message}' was raised while opening git repo, then '#{create_error.message}' was while trying to create git repo"
      end
      retry
    end
  end

  def update_repo repo, file, data, msg, user, email
    oid = repo.write data, :blob
    index = repo.index
    index.read_tree repo.head.target.tree unless repo.empty?

    tree_old = index.write_tree repo
    index.add :path=>file, :oid=>oid, :mode=>0100644
    tree_new = index.write_tree repo

    if tree_old != tree_new
      repo.config['user.name']  = user
      repo.config['user.email'] = email
      @commitref = Rugged::Commit.create(repo,
        :tree       => index.write_tree(repo),
        :message    => msg,
        :parents    => repo.empty? ? [] : [repo.head.target].compact,
        :update_ref => 'HEAD',
      )

      index.write
      true
    end
  end
end
end
