class Airfiber < Oxidized::Model
  using Refinements

  # Ubiquiti Airfiber (tested with Airfiber 11FX)

  prompt /^AF[\w\.-]+#/i

  cmd :all do |cfg|
    cfg.cut_both
  end

  pre do
    cmd 'cat /tmp/system.cfg'
  end

  cfg :telnet do
    username /^[\w\W]+\slogin:\s$/
    password /^[p:P]assword:\s$/
  end

  cfg :telnet, :ssh do
    pre_logout 'exit'
  end
end
