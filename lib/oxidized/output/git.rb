module Oxidized
class Git < Output
  class GitError < OxidizedError; end
  begin
    gem 'rugged', '~> 0.21.0'
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

  def store file, outputs, opt={}
    @msg   = opt[:msg]
    @user  = (opt[:user]  or @cfg.user)
    @email = (opt[:email] or @cfg.email)
    @opt   = opt
    repo   = @cfg.repo

    outputs.types.each do |type|
      type_cfg = ''
      type_repo = File.join File.dirname(repo), type + '.git'
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

  def update repo, file, data
    return if data.empty?
    if @opt[:group]
      repo = File.join File.dirname(repo), @opt[:group] + '.git'
    end
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
      Rugged::Commit.create(repo,
        :tree       => index.write_tree(repo),
        :message    => msg,
        :parents    => repo.empty? ? [] : [repo.head.target].compact,
        :update_ref => 'HEAD',
      )
    end
  end
end
end
