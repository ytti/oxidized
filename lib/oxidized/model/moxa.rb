class Moxa < Oxidized::Model
  using Refinements

  # Tested on EDS EDS-510E (v5.5), EDS-408A-SS-SC V3.13
  # Default login must be turn to shell : 1 Basic Settings, Login mode, Toggle login mode)

  prompt prompt /.*#/
  # prompt /^(\r*[\w\s.@()\/:-]+[#>]\s?)$/
  comment '! '

  cmd 'show version' do |cfg|
    comment cfg
  end


  cmd 'show running-config'

  cfg :telnet do
    # login as:
    username /login as:/
    # password:
    password /password:/
  end

  cfg :telnet, :ssh do
    post_login 'terminal length 0'
    pre_logout 'logout'
  end
end
