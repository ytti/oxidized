class FortiADC < Oxidized::Model
  prompt /\(.*\) (.*) \$/

  cmd :all do |cfg, cmdstring|
    new_cfg = comment "COMMAND: #{cmdstring}\n"
    new_cfg << cfg.each_line.to_a[1..-2].map { |line| line.gsub(/(conf_file_ver=)(.*)/, '\1<stripped>\3') }.join
  end

  expect /^--More--\s$/ do |data, re|
    send ' '
    data.sub re, ''
  end

   cmd 'show' do |cfg|
         comment cfg
    end

  cfg :telnet, :ssh do
    pre_logout "exit\n"
  end
end
