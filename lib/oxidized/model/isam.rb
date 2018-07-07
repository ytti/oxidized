class ISAM < Oxidized::Model
  # Alcatel ISAM 7302/7330 FTTN

  prompt /^([\w.:@-]+>#\s)$/
  comment '# '

  cmd :all do |cfg|
    cfg.cut_both
  end

  cfg :telnet do
    username /^login:\s*/
    password /^password:\s*/
  end

  cfg :telnet, :ssh do
    post_login 'environment prompt "%n># "'
    post_login 'environment mode batch'
    post_login 'environment inhibit-alarms print no-more'
    pre_logout 'logout'
  end

  cmd 'show software-mngt oswp detail' do |cfg|
    comment cfg
  end

  cmd 'show equipment slot detail' do |cfg|
    comment cfg
  end

  cmd 'info configure flat' do |cfg|
    cfg
  end
end
