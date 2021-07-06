class VRP58 < Oxidized::Model
  # Huawei VRP MA5800

  prompt /^([\w.-]+(>|#))$/
  comment '# '

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  cfg :telnet do
    username /^(>>User name:)$/
    password /^(>>User password:)$/
  end

  cfg :telnet, :ssh do
    post_login 'enable'
    pre_logout "quit\ny\n"
  end

  cmd "display board serial-number 0 | no-more \n" do |cfg|
    comment cfg
  end

  cmd "display version | no-more \n" do |cfg|
    cfg = cfg.each_line.select {|l| not l.match /Uptime/ }.join
    comment cfg
  end

  cmd "display current-configuration | no-more \n" do |cfg|
    cfg
  end

end
