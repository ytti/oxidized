class FortiFAZ < Oxidized::Model
  comment '# '

  prompt /.+?(?=\ #)\ #/

  cmd :all do |cfg, cmdstring|
    new_cfg = comment "COMMAND: #{cmdstring}\n"
    new_cfg << cfg.each_line.to_a[1..-2].map { |line| line.gsub(/(conf_file_ver=)(.*)/, '\1<stripped>\3') }.join
  end

    cmd 'get system status' do |cfg|
        comment cfg
    end

    cmd 'get sys global' do |cfg|
        comment cfg
    end

    cmd 'get sys performance' do |cfg|
        comment cfg
    end

    cmd 'diagnose hardware info' do |cfg|
        comment cfg
    end

    cmd 'show' do |cfg|
        comment cfg
    end

  cfg :ssh do
    password /^Password:/
  end

  cfg :ssh do
    pre_logout "exit\n"
  end
end
