class Aireos < Oxidized::Model
  # AireOS (at least I think that is what it's called, hard to find data)
  # Used in Cisco WLC 5500

  comment '# ' # this complains too, can't find real comment char
  prompt /^\([^)]+\)\s>/

  cmd :all do |cfg|
    cfg.cut_both
  end

  # show sysinfo?
  # show switchconfig?

  cmd 'show udi' do |cfg|
    cfg = comment clean cfg
    cfg << "\n"
  end

  cmd 'show boot' do |cfg|
    cfg = comment clean cfg
    cfg << "\n"
  end

  cmd 'show run-config commands' do |cfg|
    clean cfg
  end

  cfg :telnet, :ssh do
    username /^User:\s*/
    password /^Password:\s*/
    post_login 'config paging disable'
  end

  cfg :telnet, :ssh do
    pre_logout do
      send "logout\n"
      send "n"
    end
  end

  def clean(cfg)
    out = []
    cfg.each_line do |line|
      next if line =~ /^\s*$/
      next if line =~ /rogue (adhoc|client) (alert|Unknown) [\da-f]{2}:/

      line = line[1..-1] if line[0] == "\r"
      out << line.strip
    end
    out = out.join "\n"
    out << "\n"
  end
end
