class AsterNOS < Oxidized::Model
  using Refinements

  prompt /^[^\$]+\$/
  comment '# '

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  cmd 'show version' do |cfg|
    # @model = Regexp.last_match(1) if cfg =~ /^Model: (\S+)/
    comment cfg
  end

  cmd "show runningconfiguration all"

  cfg :ssh do
    # exec true
    pre_logout 'exit'
  end
end
