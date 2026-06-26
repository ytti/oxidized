class EatonNetwork < Oxidized::Model
  using Refinements
  # Eaton Gigabit Network Card M3

  # -p option is a passphrase used to encrypted parts of the config data, the
  # encrypted data is nondeterministic and changes with each run. Use auth
  # password as the passphrase.
  #
  # See docs/Model-Notes/EatonNetwork.md for more info
  post do
    # Get config in post to allow passing auth password to cmd.
    cmd "save_configuration -p #{@node.auth[:password]}"
  end

  cmd :all do |cfg|
    # save_configuration echoes the command and date/time around the JSON
    # config (a single line) and ends with the prompt; keep only the JSON.
    json = JSON.parse(cfg.keep_lines([/^\{/]))

    json.dig('features', 'userAndSessionManagement', 'data', 'settings', 'all', '1.0', 'local', '1.0').tap do |key|
      (key['predefinedAccounts'] + key['createdAccounts']).each do |account|
        account.delete('attemptLogin')
        account['password'].delete('history')
      end
    end

    JSON.pretty_generate(json)
  end

  cmd :secret do |cfg|
    # Re-parse json to remove secrets by json path
    json = JSON.parse(cfg)

    json.delete('passphrase')

    json.dig('features', 'rms', 'data', 'settings').tap do |key|
      key.delete('proxyUsername')
      key.delete('proxyPassword')
      key.delete('username')
      key.delete('password')
      key.delete('defaultPassword')
    end

    json.dig('features', 'smtp', 'data', 'dmeData').delete('password')

    json.dig('features', 'snmp', 'data', 'dmeData', 'v3', 'users').each do |key|
      key['auth'].delete('password')
      key['priv'].delete('password')
    end

    json.dig('features', 'userAndSessionManagement', 'data', 'settings', 'all', '1.0').tap do |key|
      key.dig('ldap', '1.0', 'settings', 'connectivity', 'bind').delete('password')
      key.dig('radius', '1.0', 'settings', 'connectivity').tap do |radius|
        radius['primaryServer'].delete('secret')
        radius['secondaryServer'].delete('secret')
      end
    end

    # Added in firmware v2.2.0
    json.dig('features', 'peripherals', 'data', 'dmeData', 'ethernet', 'ports').each do |key|
      key.dig('dot1x', 'peap', 'password') && key['dot1x']['peap'].delete('password')
    end

    JSON.pretty_generate(json)
  end

  cfg :ssh do
    exec true
    pre_logout 'logout'
  end
end
