class QuantaOS < Oxidized::Model
  using Refinements

  prompt /^\(\S+\) (>|#)$/
  comment '! '

  cmd :all do |cfg|
    # Remove command echo and prompt
    cfg.cut_both
  end

  cmd 'show run' do |cfg|
    # Remove commented lines
    cfg.lines.grep_v(/^!/).join
  end

  cfg :telnet do
    username /^User(name)?:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    post_login do
      send "enable\n"
      cmd vars(:enable) || ""
    end
    post_login 'terminal length 0'
    pre_logout do
      send "quit\n"
      send "n\n"
    end
  end
end
