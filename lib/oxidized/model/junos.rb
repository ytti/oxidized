class JunOS < Oxidized::Model

  comment  '# '

  def telnet
    @input.class.to_s.match(/Telnet/)
  end

  cmd :all do |cfg|
    # we don't need screen-scraping in ssh due to exec
    cfg = cfg.lines.to_a[1..-2].join if telnet
    cfg.lines.map { |line| line.rstrip }.join("\n") + "\n"
  end

  cmd :secret do |cfg|
    cfg.gsub!(/encrypted-password (\S+).*/, '<secret removed>')
    cfg.gsub!(/community (\S+) {/, 'community <hidden> {')
    cfg
  end

  cmd 'show configuration | display omit'

  cmd 'show version detail' do |cfg|
    @model = $1 if cfg.match(/^Model: (\S+)/)
    comment cfg
  end

  post do
    out = ''
    case @model
    when 'mx960'
      out << cmd('show chassis fabric reachability')  { |cfg| comment cfg }
    when 'mx480'
      out << cmd('show chassis scb')  { |cfg| comment cfg }
      out << cmd('show chassis sfm detail')  { |cfg| comment cfg }
      out << cmd('show chassis ssb')  { |cfg| comment cfg }
      out << cmd('show chassis feb detail')  { |cfg| comment cfg }
      out << cmd('show chassis feb')  { |cfg| comment cfg }
      out << cmd('show chassis cfeb')  { |cfg| comment cfg }
    end
    out
  end

  cmd('show chassis environment') { |cfg| comment cfg }
  cmd('show chassis firmware') { |cfg| comment cfg }
  cmd('show chassis fpc detail') { |cfg| comment cfg }
  cmd('show chassis hardware detail') { |cfg| comment cfg }
  cmd('show chassis routing-engine') { |cfg| comment cfg }
  cmd('show chassis alarms') { |cfg| comment cfg }
  cmd('show system license') { |cfg| comment cfg }
  cmd('show system boot-messages') { |cfg| comment cfg }
  cmd('show system core-dumps') { |cfg| comment cfg }

  cfg :telnet do
    username(/^login:/)
    password(/^Password:/)
  end

  cfg :ssh do
    exec true  # don't run shell, run each command in exec channel
  end

  cfg :telnet, :ssh do
    post_login 'set cli screen-length 0'
    post_login 'set cli screen-width 0'
    pre_logout 'exit'
  end

end
