module Oxidized
class Git < Output
  require 'grit'
  require 'oxidized/fix/grit' if RUBY_VERSION[0..1] == '2.'
  include Grit

  def initialize
    @cfg = CFG.output[:git]
  end

  def setup
    if not @cfg
      CFG.output[:git] = {
        :user  => 'Oxidized',
        :email => 'o@example.com',
        :repo  => File.join(Config::Root, 'oxidized.git')
      }
      CFG.save
    end
  end

  def store file, data, opt={}
    msg   = opt[:msg]
    user  = (opt[:user]  or @cfg[:user])
    email = (opt[:email] or @cfg[:email])
    repo  = @cfg[:repo]
    if opt[:group]
      repo = File.join File.dirname(repo), opt[:group] + '.git'
    end
    begin
      repo = Repo.new repo
      actor = Actor.new user, email
      update_repo repo, file, data, msg, actor
    rescue Grit::NoSuchPathError
      Repo.init_bare repo
      retry
    end
  end

  private

  def update_repo repo, file, data, msg, actor
    index  = repo.index
    index.read_tree 'master'
    old = index.write_tree index.tree, index.current_tree
    index.add file, data
    new = index.write_tree index.tree, index.current_tree
    if old != new
      parent = repo.commits(nil, 1).first
      parent = [parent] if parent
      Log.debug "GIT: comitting #{file}"
      index.commit msg, parent, actor
    end
  end
end
end
