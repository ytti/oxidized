class AudioCodesMP < Oxidized::Model
  # AudioCodes MediaPack MP1xx and Mediant 1000 devices (firmware v4.xx, v5.xx, v6.xx) by pedjajks@gmail.com

  prompt /^\/\w*>/

  comment ';'

  cmd 'conf' do
  end

  cmd 'cf get' do |cfg|
    lines = cfg.each_line.to_a[0..-1]
    # remove any garbage before ';**************' and after '; End of INI file.'
    lines[lines.index(";**************\r\n")..lines.index("; End of INI file.\n")].join
  end

  cfg :ssh do
    username /^login as:\s$/
    password /^.+password:\s$/
    pre_logout 'exit'
  end

  cfg :telnet do
    username /login:\s$/
    password /password:\s$/
    pre_logout 'exit'
  end
end
