class TDRE < Oxidized::Model
  using Refinements

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
      cfg.cut_both(5, 3)
    else
      cfg.cut_both(1, 3)
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
