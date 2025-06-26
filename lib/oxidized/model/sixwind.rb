class SixWind < Oxidized::Model
  using Refinements

  prompt /^[\w\s\(\).@_\/:-]+[>] $/
  comment '# '

  cmd :all do |cfg|
    cfg.cut_both
  end

  cmd :secret do |cfg|
    cfg.gsub!(/(?<!  {1})(?:password|secret) (?:\d )?\S+/, '\\1 <secret hidden>') # double space to exclude radius password template
    cfg
  end

  cmd 'show product version' do |cfg|
    comment cfg
  end

  cmd 'show config' do |cfg|
    cfg
  end

  cfg :ssh do
    post_login 'cliconfig pager enabled false'
    pre_logout 'exit'
  end
end
