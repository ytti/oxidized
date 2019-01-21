class AudioCodesMP < Oxidized::Model
  # AudioCodes MediaPack MP1xx and Mediant 1000 devices (firmware v4.xx, v5.xx, v6.xx)
  # Created by pedjajks@gmail.com
  # 2019 v3.0


#   prompt /(\/.*?>)/
   prompt /\/>|\/CONFiguration>/

  comment ';'

  cmd 'cf get' do |cfg|
    # remove Unnecessary Lines
    # cfg.gsub! /^AutoUPDate SaveAndReset*/, ''
    cfg.gsub! /^cf get*/, ''
    cfg.gsub! /^SIP\/ SECurity.*/, ''
    cfg.gsub! /^SaveAndReset RestoreFactorySettings.*/, ''
    cfg.gsub! /^\/CONFiguration>.*/, ''
    cfg.gsub! /^PING SHow*/, ''
    cfg.gsub! /\/>.*/, ''
    cfg
  end


  cfg :ssh do
    username /^login as:\s$/
    password /^.+password:\s$/
    pre_logout 'exit'
  end

  cfg :telnet do
    username /login:/
    password /password:/
    post_login 'conf'
    pre_logout 'exit'
  end
end
