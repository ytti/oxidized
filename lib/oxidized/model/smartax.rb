class SmartAX < Oxidized::Model
  # Huawei SmartAX
  
  prompt /^([\w.-]+[>#])$/

  comment '#'

  cfg :telnet do
    username /^>>User name:$/
    password /^>>User password:$/
  end

  cfg :ssh, :telnet do
    post_login "enable"
    post_login "undo interactive"
    post_login "undo smart"
    post_login "scroll"
    pre_logout "quit"
  end

  cmd 'display current-configuration'

end
