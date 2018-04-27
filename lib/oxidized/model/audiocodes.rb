class AudioCodes < Oxidized::Model
  # Pull config from AudioCodes Mediant devices from version > 7.0

  prompt /^\r?([\w.@() -]+[#>]\s?)$/
  comment '## '

  expect /\s*--MORE--$/ do |data, re|
    send ' '

    data.sub re, ''
  end

  cmd 'show running-config' do |cfg|
    cfg
  end

  cfg :ssh do
    username /^login as:\s$/
    password /^.+password:\s$/
    pre_logout 'exit'
  end

  cfg :telnet do
    username /^Username:\s$/
    password /^Password:\s$/
    pre_logout 'exit'
  end
end
