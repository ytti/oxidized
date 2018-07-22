class Netgear < Oxidized::Model
  comment '!'
  prompt /^(\([\w\s\-.]+\)\s[#>])$/

  cmd :secret do |cfg|
    cfg.gsub!(/password (\S+)/, 'password <hidden>')
    cfg.gsub!(/encrypted (\S+)/, 'encrypted <hidden>')
    cfg
  end

  cfg :telnet do
    username /^(User:|Applying Interface configuration, please wait ...)/
    password /^Password:/i
  end

  cfg :telnet, :ssh do
    post_login do
      if vars(:enable) == true
        cmd "enable"
      elsif vars(:enable)
        cmd "enable", /[pP]assword:\s?$/
        cmd vars(:enable)
      end
    end
    post_login 'terminal length 0'
    # quit / logout will sometimes prompt the user:
    #
    #     The system has unsaved changes.
    #     Would you like to save them now? (y/n)
    #
    # So it is safer simply to disconnect and not issue a pre_logout command
  end

  cmd 'show running-config' do |cfg|
    cfg.gsub! /^(!.*Time).*$/, '\1'
  end
end
