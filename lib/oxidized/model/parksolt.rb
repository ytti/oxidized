class PARKSOLT < Oxidized::Model
  using Refinements

  # PARKS OLT #

  prompt /^(\r?[\w.@:\/-]+[#>]\s?)$/
  comment  '! '

  cmd :all do |cfg|
    cfg.each_line.to_a[2..-2].join
  end

  cmd 'show running-config' do |cfg|
    cfg = cfg.each_line.to_a[1..-1].join
    cfg
  end

  cfg :ssh do
    post_login 'terminal length 0'
    pre_logout 'exit'
  end
end
