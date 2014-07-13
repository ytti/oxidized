module Oxidized
class Git < Output
  begin
    require 'rugged'
  rescue LoadError
    raise OxidizedError, 'rugged not found: sudo gem install rugged'
  end

  def initialize
    @cfg = CFG.output.git
  end

  def setup
    if @cfg.empty?
      CFGS.user.output.git.user  = 'Oxidized'
      CFGS.user.output.git.email = 'o@example.com'
      CFGS.user.output.git.repo  =  File.join(Config::Root, 'oxidized.git')
      CFGS.save :user
      raise NoConfig, 'no output git config, edit ~/.config/oxidized/config'
    end
  end

  def store file, data, opt={}
    msg   = opt[:msg]
    user  = (opt[:user]  or @cfg.user)
    email = (opt[:email] or @cfg.email)
    repo  = @cfg.repo
    if opt[:group]
      repo = File.join File.dirname(repo), opt[:group] + '.git'
    end
    begin
      repo = Rugged::Repository.new repo
      update_repo repo, file, data, msg, user, email
    rescue Rugged::OSError, Rugged::RepositoryError
      Rugged::Repository.init_at repo, :bare
      retry
    end
  end

  def fetch node, group
    begin
      repo = @cfg.repo
      if group
        repo = File.join File.dirname(repo), group + '.git'
      end
      repo = Rugged::Repository.new repo
      index = repo.index
      index.read_tree repo.head.target.tree unless repo.empty?
      repo.read(index.get(node)[:oid]).data
    rescue
      'node not found'
    end
  end

  private

  def update_repo repo, file, data, msg, user, email
    oid = repo.write data, :blob
    index = repo.index
    index.read_tree repo.head.target.tree unless repo.empty?

    tree_old = index.write_tree repo
    index.add :path=>file, :oid=>oid, :mode=>0100644
    tree_new = index.write_tree repo

    if tree_old != tree_new
      Rugged::Commit.create(repo,
        :tree       => index.write_tree(repo),
        :message    => msg,
        :parents    => repo.empty? ? [] : [repo.head.target].compact,
        :update_ref => 'HEAD',
        :author     => {:name=>user, :email=>email, :time=>Time.now.utc}
      )
    end
  end
end
end
