class Procurve < Oxidized::Model

  # FIXME: this is way too unsafe
  prompt /.*?(\w+# ).*/m

  comment  '! '

  expect /Press any key to continue/ do
     send ' '
     ""
  end

  cmd :all do |cfg|
    cfg = cfg.each_line.to_a[1..-3].join
    cfg = cfg.gsub /\r/, ''
    new_cfg = ''
    cfg.each_line do |line|
      line.sub! /^\e.*(\e.*)/, '\1'  #leave last escape
      line.sub! /\e\[24;1H/, ''      #remove last escape, is it always this?
      new_cfg << line
    end
    new_cfg
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show system-information' do |cfg|
    comment cfg
  end

  cmd 'show running-config'

  cfg :telnet do
    username /Username:/
    password /Password:/
  end

  cfg :telnet, :ssh do
    post_login 'no page'
    pre_logout "logout\ny"
  end

end
