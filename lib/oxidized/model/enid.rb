class ENID < Oxidized::Model
    # Support for Accedian EtherNID family
  
    comment '#'
    prompt /^(\w+-\w+):\s?$/
  
    cmd 'port show status' do |cfg|
      comment cfg
    end
  
    cmd 'configuration export' do |cfg|
      cfg.gsub! /^.*FILE_ATTRIB.*/, ''
      cfg.gsub! /^.*Export Done.*/, ''
      cfg.cut_both
    end
  
    cfg :telnet do
      username /^(\w+-\w+\s+login:)\s?$/
      password /[Pp]assword:\s?/
    end
  
    cfg :ssh do |cfg|
      post_login 'session writelock'
      pre_logout 'session writeunlock'
      pre_logout 'exit'
    end
  end