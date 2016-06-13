class Quanta < Oxidized::Model

  prompt /^\((\w|\S)+\) (>|#)$/
  comment '! '
  cmd 'show run' do |cfg|
    cfg = cfg.each_line.select { |line| not line.match /^!.*$/ }
    cfg = cfg.join
    cfg = cfg.each_line.select { |line| not line.match /^\((\w|\S)+\) (>|#)$/ }
    cfg = cfg.join
    cfg = cfg.each_line.select { |line| not line.match /^show run$/ }
    cfg = cfg.join
  end

  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    post_login do
      send "enable\n"
      if vars :enable
        cmd vars(:enable)
      else
        cmd ""
      end
    end
    post_login 'terminal length 0'
    pre_logout do
      send "quit\n"
      send "n\n"
    end
  end

end
