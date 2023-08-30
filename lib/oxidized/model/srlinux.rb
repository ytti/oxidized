class SRLinux < Oxidized::Model
  using Refinements

  # https://regex101.com/r/PGLSJJ/1
  # prompt /^--{(\s\[[\w\s]+\]){0,5}[\+\*\s]{1,}running\s}--\[.+?\]--\s*\n[abcd]:\S+#\s*$/i
  prompt /[ABCD]:\S+#\s*/

  comment '# '

  cmd :all do |cfg|
    cfg.cut_both
    # since multiline regexp for prompt doesn't seem to work, let's cut the remaining line with this
    cfg.gsub! /--{(?:\s\[[\w\s]+\]){0,5}[\+\*\s]{1,}running\s}--\[.+?\]--/, ''
    cfg
  end

  cmd :secret do |cfg|
    cfg.gsub! /password (\S+)/, 'password <hidden>'
    cfg
  end

  cmd 'info flat'

  cmd 'show version | grep -v "Free Memory"' do |cfg|
    # Free Memory will fluctuate, causing updates
    comment cfg
  end

  cmd 'show platform chassis' do |cfg|
    comment cfg
  end

  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  cfg :ssh do
    exec true
  end

  cfg :telnet, :ssh do
    post_login 'environment cli-engine type basic'
    pre_logout 'quit'
  end
end
