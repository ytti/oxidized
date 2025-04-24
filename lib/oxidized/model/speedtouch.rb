class SpeedTouch < Oxidized::Model
  using Refinements

  prompt /([\w{}=]+[>])$/
  comment '! '

  expect /login$/ do
    send "\n"
    ""
  end

  cmd ':env list' do |cfg|
    cfg.each_line.select do |line|
      (!line.match /:env list$/) &&
        (!line.match /{\w+}=>$/)
    end.join
    comment cfg
  end

  cmd ':config dump' do |cfg|
    cfg.each_line.select do |line|
      (!line.match /:config dump$/) &&
        (!line.match /{\w+}=>$/)
    end.join
    cfg
  end

  cfg :telnet do
    username /^Username : /
    password /^Password : /
  end

  cfg :telnet do
    pre_logout 'exit'
  end
end
