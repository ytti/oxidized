class RouterOS < Oxidized::Model
  prompt /\[\w+@\S+\]\s?>\s?$/
  comment "# "

  cmd '/system routerboard print' do |cfg|
    comment cfg
  end

  cmd '/export' do |cfg|
    cfg.gsub! /\[(?:\d+)?(?:;\d+)?(?:m)?/, '' # strip ANSI colours
    cfg = cfg.split("\n").select { |line| not line[/^\#\s\w{3}\/\d{2}\/\d{4}.*$/] }
    cfg.join("\n") + "\n"
  end

  cfg :telnet do
    username /^Login:/
    password /^Password:/
  end

  cfg :ssh do
    exec true
  end
end
