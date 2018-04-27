class SGOS < Oxidized::Model
  comment '!- '
  prompt /\w+>|#/

  expect /--More--/ do |data, re|
    send ' '
    data.sub re, ''
  end

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-3].join
  end

  cmd 'show licenses' do |cfg|
    comment cfg
  end

  cmd 'show general' do |cfg|
    comment cfg
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(security hashed-enable-password).*/, '\\1 <secret hidden>'
    cfg.gsub! /^(security hashed-password).*/, '\\1 <secret hidden>'
    cfg
  end

  cmd 'show configuration expanded noprompts with-keyrings unencrypted' do |cfg|
    cfg.gsub! /^(!- Local time).*/, ""
    cfg.gsub! /^(archive-configuration encrypted-password).*/, ""
    cfg.gsub! /^(download encrypted-password).*/, ""
    cfg
  end

  cfg :telnet, :ssh do
    # preferred way to handle additional passwords
    if vars :enable
      post_login do
        send "enable\n"
        cmd vars(:enable)
      end
    end
    pre_logout 'exit'
  end
end
