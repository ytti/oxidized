class TDRE < Oxidized::Model

  prompt /^>$/ 
  cmd "get -f"

  def ssh
    @input.class.to_s.match(/SSH/)
  end

  expect /^>.+$/ do |data, re|
    send "\r" if ssh
    data.sub re, ''
  end

  cmd :all do |cfg|
    if ssh
    cfg = cfg.lines.to_a[5..-4].join
    else
    cfg = cfg.lines.to_a[1..-4].joim
    end
  end

  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    pre_logout "DISCONNECT\r" 
  end

end
