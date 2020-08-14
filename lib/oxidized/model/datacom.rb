class DataCom < Oxidized::Model
  # editing model specific prompt RegEx, adding: [\n]?
  # to workaround the new DmOS post login welcome message
  prompt /([\n]?[\w-]+[(]*[\w-]*[)]*[#>][\s]?)$/
  comment '! '

  # was not able to make expect method work for pagination
  # expect /([\n]?[\s]*--More--[\s]*)$/ do |data, re|
  #   send ' '
  #   data.sub re, ''
  # end

  cmd :all do |cfg|
    cfg.cut_both
  end

  cmd 'show firmware' do |cfg|
    # since 'show firmware' does not paginate in neither firmware versions,
    # chose to use it's output to distinguish between the old and new OS
    if cfg.lines.first =~ /^Running firmware:\s*$/ # Old OS firmware
      Oxidized.logger.debug 'lib/oxidized/model/datacom.rb Legacy firmware (disabling pagination)'
      cmd "config\nno terminal paging\nexit"
    else # New DmOS firmware
      Oxidized.logger.debug 'lib/oxidized/model/datacom.rb DmOS firmware (disabling pagination)'
      cmd "paginate false"
    end
    comment cfg
  end

  cmd 'show system' do |cfg|
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg.cut_head
  end

  cmd 'show firmware' do |cfg|
    # sorry, but I could not figure out a way to carry updated @legacy var in routine execution
    if cfg.lines.first =~ /^Running firmware:\s*$/ # Old OS firmware
      Oxidized.logger.debug 'lib/oxidized/model/datacom.rb Legacy firmware (enabling pagination)'
      cmd("config\nterminal paging\nexit")
    else # New DmOS firmware
      Oxidized.logger.debug 'lib/oxidized/model/datacom.rb DmOS firmware (enabling pagination)'
      cmd("paginate true")
    end
  end

  cfg :ssh do
    password /^Password:\s$/
    pre_logout 'exit'
  end

  cfg :telnet do
    username /login:\s$/
    password /^Password:\s$/
    pre_logout 'exit'
  end
end
