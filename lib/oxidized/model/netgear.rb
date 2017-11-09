class Netgear < Oxidized::Model

  comment '!'
  prompt /^(\([\w-]+\)\s[#>])$/

  cmd :secret do |cfg|
    cfg.gsub!(/password (\S+)/, 'password <hidden>')
    cfg
  end

  cfg :telnet do
    username /^User:/
  end

  cfg :telnet, :ssh do
    if vars :enable
      post_login do
        send "enable\n"
        # Interpret enable: true as meaning we won't be prompted for a password
        unless vars(:enable).is_a? TrueClass
          expect /[pP]assword:\s?$/
          send vars(:enable) + "\n"
        end
        expect /^.+[#]$/
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
