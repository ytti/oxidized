class DataCom < Oxidized::Model
  # editing model specific prompt RegEx, adding: [\n]?
  # to workaround the new DmOS post login welcome message
  prompt /([\n]?[\w-]+[(]*[\w-]*[)]*[#>][\s]?)$/
  # @legacy => false: new DmOS firmware | true: old OS firmware
  @legacy = false
  comment '! '

# was not able to make expect method work for pagination
#  expect /^\s*--More--\s*$/ do |data, re|
#    send ' '
#    data.sub re, ''
#  end

  cmd :all do |cfg|
    cfg.cut_both
  end

  cmd 'show firmware' do |cfg|
    # since 'show firmware' does not paginate in neither firmware versions,
    # chose to use it's output to distinguish between the old and new OS
    if cfg.lines.first =~ /^Running firmware:\s*$/  # Old OS firmware
      @legacy = true
      cmd "config\nno terminal paging\nexit"
    else  # New DmOS firmware
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

  if @legacy == true
    cmd "config\nterminal paging\nexit"
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