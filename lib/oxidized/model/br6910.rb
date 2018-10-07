class BR6910 < Oxidized::Model
  prompt /^([\w.@()-]+[#>]\s?)$/
  comment '! '

  # not possible to disable paging prior to show running-config
  expect /^((.*)Others to exit ---(.*))$/ do |data, re|
    send 'a'
    data.sub re, ''
  end

  cmd :all do |cfg|
    # sometimes br6910s inserts arbitrary whitespace after commands are
    # issued on the CLI, from run to run.  this normalises the output.
    cfg.each_line.to_a[1..-2].drop_while { |e| e.match /^\s+$/ }.join
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  # show flash is not possible on a brocade 6910, do dir instead
  # to see flash contents (includes config file names)
  cmd 'dir' do |cfg|
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    arr = cfg.each_line.to_a
    arr[2..-1].join unless arr.length < 2
  end

  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  # post login and post logout
  cfg :telnet, :ssh do
    post_login ''
    pre_logout 'exit'
  end
end
