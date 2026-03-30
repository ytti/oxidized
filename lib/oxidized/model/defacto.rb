class Defacto < Oxidized::Model
  prompt /^(\r*[\w.:@()\/_-]+[#>]\s?)$/
  comment '! '

  clean :cut

  post do
    cmd "show running-config" do |cfg|
      process_config cfg
    end
  end

  cfg :telnet do
    username /^(user ?name|login|user)/i
    password /^password/i
  end

  cfg :telnet, :ssh do
    post_login 'terminal length 0'
    post_login 'terminal width 0'
    pre_logout 'exit'
    pre_logout 'logout'
  end

  def process_config(cfg) = cfg
end
