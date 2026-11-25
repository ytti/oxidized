class CoriantGroove < Oxidized::Model
  using Refinements

  comment '# '

  prompt /^(\w+@.*>\s*)$/

  cmd :all do |cfg|
    cfg.delete("\r").cut_both(1, 2).rstrip_lines
  end

  cmd 'show inventory' do |cfg|
    comment cfg.cut_tail
  end

  cmd 'show softwareload' do |cfg|
    comment cfg.cut_tail
  end

  cmd 'show config | display commands' do |cfg|
    cfg.cut_head
  end

  cfg :ssh do
    post_login 'set -f cli-config cli-columns 4000'
    pre_logout 'quit -f'
  end
end
