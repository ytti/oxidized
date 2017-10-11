class CoriantGroove < Oxidized::Model

  comment '# '
  
  prompt /^(\w+@.*>\s*)$/

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-3].map{|line|line.delete("\r").rstrip}.join("\n") + "\n"
  end

  cmd 'show inventory' do |cfg|
    cfg = cfg.each_line.to_a[0..-2].join
    comment cfg
  end

  cmd 'show softwareload' do |cfg|
    cfg = cfg.each_line.to_a[0..-2].join
    comment cfg
  end
  
  cmd 'show config | display commands' do |cfg|
    cfg.each_line.to_a[1..-1].join
  end

  cfg :ssh do
    post_login 'set -f cli-config cli-columns 65535'
    pre_logout 'quit -f'
  end

end
