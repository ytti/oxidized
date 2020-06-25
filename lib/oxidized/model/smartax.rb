class SmartAX < Oxidized::Model
  # Huawei SmartAX GPON/EPON/DOCSIS network access devices
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

  # 'display current-configuration' returns current configuration stored in memory
  # 'display saved-configuration'   returns configuration stored in the file system which is used upon reboot
  cmd 'display current-configuration' do |cfg|
    cfg.cut_both
  end
end
