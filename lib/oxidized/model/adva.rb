# Oxidized model for ADVA devices
#
# IMPORTANT: To get this working, cli-paging must be disabled
# for the user that is used to fetch the configuration.

class ADVA < Oxidized::Model
  using Refinements

  prompt /\w+-+[#>]\s?$/
  comment '# '

  cmd :secret do |cfg|
    cfg.gsub! /community "[^"]+"/, 'community "<hidden>"'
    cfg
  end

  cmd :all do |cfg|
    cfg.cut_both
  end

  cmd 'show running-config delta' do |cfg|
    cfg.each_line.reject { |line| line.match /^Preparing configuration file.*/ }.join
  end

  cmd 'show system' do |cfg|
    cfg = cfg.each_line.reject { |line| line.match /(up time|local time)/i }.join

    cfg = "COMMAND: show system\n\n" + cfg
    cfg = comment cfg
    "\n\n" + cfg
  end

  cmd 'network-element ne-1'

  cmd 'show shelf-info' do |cfg|
    cfg = "COMMAND: show shelf-info\n\n" + cfg
    cfg = comment cfg
    "\n\n" + cfg
  end

  post do
    ports = []
    ports_output = ''

    cmd 'show ports' do |cfg|
      cfg.each_line do |line|
        port = line.match(/\|((access|network)[^\|]+)\|/)
        ports << port if port
      end
    end

    ports.each do |port|
      port_command = 'show ' + port[2] + '-port ' + port[1]

      ports_output << cmd(port_command) do |cfg|
        cfg = "COMMAND: " + port_command + "\n\n" + cfg
        cfg = comment cfg
        "\n\n" + cfg
      end
    end

    ports_output
  end

  cfg :ssh do
    pre_logout 'logout'
  end
end
