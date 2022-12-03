# Mikrotik SwOS (Lite)
class SwOS < Oxidized::Model
  cmd '/backup.swb'
  cfg :http do
    @username = @node.auth[:username]
    @password = @node.auth[:password]
    @secure = false
  end
end
