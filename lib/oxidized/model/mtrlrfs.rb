class Mtrlrfs < Oxidized::Model
  using Refinements

  # Motorola RFS/Extreme WM

  prompt /^([\w.@-]+\*?[#>])\s?$/
  comment  '# '

  cmd :all do |cfg|
    # xos inserts leading \r characters and other trailing white space.
    # this deletes extraneous \r and trailing white space.
    cfg.delete("\r").cut_both.rstrip_lines
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show licenses' do |cfg|
    comment cfg
  end

  cmd 'show running-config'

  cfg :telnet do
    username /^login:/
    password /^\r*password:/
  end

  cfg :telnet, :ssh do
    post_login 'terminal length 0'
    pre_logout do
      send "exit\n"
      send "n\n"
    end
  end
end
