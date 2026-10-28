class Garderos < Oxidized::Model
  using Refinements
  # Garderos GmbH https://www.garderos.com/
  # Routers for harsh environments
  # grs = Garderos Router Software

  prompt /[\w-]+# /
  clean :escape_codes
  comment '# '

  cmd :all do |cfg|
    # Remove the echo of the entered command and the prompt after it
    cfg.cut_both
  end

  cmd 'show system information' do |cfg|
    cfg = cfg.reject_lines [
      /^Uptime +:/,
      /^Config Age +:/,
      /^Startup +/,
      /^Wakeup Int +:/,
      /^Temperature *:/
    ]
    comment cfg + "\n"
  end

  cmd 'show hardware all' do |cfg|
    cfg = cfg.reject_lines [
      /^ +VLAN \d+/,
      /^ +Port \d+/
    ]
    comment cfg + "\n"
  end

  # If we have a radio modem installed, we'd like to list the SIM Card
  cmd 'show hardware wwan wwan0 sim' do |cfg|
    if cfg.start_with? 'Unknown command'
      String.new('')
    else
      comment cfg + "\n"
    end
  end

  cmd 'show configuration running'

  cfg :ssh do
    pre_logout 'exit'
  end
end
