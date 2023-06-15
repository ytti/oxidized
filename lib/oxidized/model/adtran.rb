class Adtran < Oxidized::Model
  using Refinements

  # Adtran

  prompt /([\w.@-]+[#>]\s?)$/

  cmd :all do |cfg|
    cfg.each_line.to_a[2..-2].map { |line| line.delete("\r").rstrip }.join("\n") + "\n"
  end

  cmd :secret do |cfg|
    cfg.gsub!(/password (\S+)/, 'password <hidden>')
    cfg
  end

  cmd 'show running-config'

  cfg :ssh do
    if vars :enable
      post_login do
        send "enable\n"
        cmd vars(:enable)
      end
    end
    post_login 'terminal length 0'
    pre_logout 'exit'
    sleep 1
  end
end
