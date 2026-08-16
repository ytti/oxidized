class IPOS < Oxidized::Model
  using Refinements

  # Ericsson SSR (IPOS)
  # Redback SE (SEOS)

  prompt /\r?([\[\]\w.@-]+[#:>]\s?)$/
  comment '! '

  cmd 'show chassis' do |cfg|
    comment cfg.cut_tail
  end

  cmd 'show hardware' do |cfg|
    comment cfg.cut_tail
  end

  cmd 'show release' do |cfg|
    comment cfg.cut_tail
  end

  cmd 'show configuration' do |cfg|
    # SEOS regularly adds some odd line breaks in random places
    # when showing the config, triggering changes.
    cfg.gsub! "\r\n", "\n"

    cfg = cfg.each_line.to_a

    # Keeps the issued command commented but removes the uncommented "Building configuration..."
    # and "Current configuration:" lines as well as the last prompt at the end.
    first_line = comment cfg.first
    cfg = cfg[1..-1]
    cfg = cfg.reject { |line| line.match /^(Building configuration|Current configuration)$/ }
    cfg.unshift first_line
    
    # Later IPOS releases add this line in addition to the usual "last changed" line.
    # It's touched regularly (as often as multiple times per minute) by the OS without actual visible config changes.
    cfg = cfg.reject { |line| line.match "Configuration last changed by system user" }

    # Earlier IPOS releases lack the "changed by system user" line and instead overwrite
    # the single "last changed by user" line. Because the line has a timestamp it will
    # trigger constant changes if not removed. By doing so there will only be a single
    # extra change trigged after an actual config change by a user but still have the
    # real user.
    cfg = cfg.reject { |line| line.match "Configuration last changed by user '%LICM%' at" }
    cfg = cfg.reject { |line| line.match "Configuration last changed by user '<NO USER>' at" }
    cfg = cfg.reject { |line| line.match "Configuration last changed by user '' at" }

    # remove last prompt
    cfg.pop if cfg.last.match(/[#:>]\s?$/)
    cfg.join
  end

  cfg :telnet do
    username /^login:/
    password /^\r*password:/
  end

  cfg :telnet, :ssh do
    post_login 'paginate false'
    if vars :enable
      post_login do
        cmd "enable"
        cmd vars(:enable)
      end
    end
    pre_logout do
      send "exit\n"
    end
  end
end
