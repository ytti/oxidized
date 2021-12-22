# For Zyxel OLTs series 1300
class Zy1300 < Oxidized::Model
  # For Zyxel OLTs series 1300

  cmd '/config_OLT-1308S-22.log'
  cfg :http do
    @username = @node.auth[:username]
    @password = @node.auth[:password]
    @secure = false
  end

end
