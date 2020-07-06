class LANCOM < Oxidized::Model
  # LANCOM Systems GmbH
  # tested on LANCOM 1781EF+ router using Lancom OS 10.32.0176RU9 / 21.04.2020
  comment '# '

  prompt />\s?$/

  cmd "sysinfo\r" do |cfg|
    cfg.gsub! /^TIME:.*\n/, ''
    comment cfg
  end

  cmd "readscript\r"

  cfg :telnet do
    username  /login:\s/
    password  /^Password:\s/
  end

  cfg :telnet, :ssh do
    pre_logout "exit\r"
  end
end
