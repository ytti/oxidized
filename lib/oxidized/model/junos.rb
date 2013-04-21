class JunOS < Oxidized::Model

  comment  '# '

  def telnet
    @input.class.to_s.match /Telnet/
  end

  cmd :all do |cfg|
    # we don't need screen-scraping in ssh due to exec
    cfg = cfg.lines[1..-2].join if telnet
    cfg
  end

  cmd 'show configuration'

  cmd 'show version' do |cfg|
    @model = $1 if cfg.match /^Model: (\S+)/
    comment cfg
  end

  def main
    case @model
    when 'mx960'
      cmd('show chassis fabric reachability')  { |cfg| comment cfg }
    end
  end

  cmd 'show chassis hardware' do |cfg|
    comment cfg
  end

  cfg :telnet do
    username  /^login:/
    password  /^Password:/
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
