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
    cfg = cmd "save_configuration -p #{@node.auth[:password]}"
    cfg
  end

  cmd :all do |cfg|
    # `save_configuration` echos the command back, outputs date time info, with
    # last line is the prompt again.
    json_str = cfg.each_line.select { |line| line.match /^\{/ }.join
    json = JSON.parse(json_str)

    json['features']['userAndSessionManagement']['data']['settings']['all']['1.0']['local']['1.0']['predefinedAccounts'].each do |n|
      n.delete('attemptLogin')
      n['password'].delete('history')
    end
    json['features']['userAndSessionManagement']['data']['settings']['all']['1.0']['local']['1.0']['createdAccounts'].each do |n|
      n.delete('attemptLogin')
      n['password'].delete('history')
    end

    cfg = JSON.pretty_generate(json)
    cfg
  end

  cmd :secret do |cfg|
    # Re-parse json to remove secrets by json path
    json = JSON.parse(cfg)

    json.delete('passphrase')
    json['features']['rms']['data']['settings'].delete('proxyUsername')
    json['features']['rms']['data']['settings'].delete('proxyPassword')
    json['features']['rms']['data']['settings'].delete('username')
    json['features']['rms']['data']['settings'].delete('password')
    json['features']['rms']['data']['settings'].delete('defaultPassword')

    json['features']['smtp']['data']['dmeData'].delete('password')

    json['features']['snmp']['data']['dmeData']['v3']['users'].each do |n|
      n['auth'].delete('password')
      n['priv'].delete('password')
    end

    json['features']['userAndSessionManagement']['data']['settings']['all']['1.0']['ldap']['1.0']['settings']['connectivity']['bind'].delete('password')
    json['features']['userAndSessionManagement']['data']['settings']['all']['1.0']['radius']['1.0']['settings']['connectivity']['primaryServer'].delete('secret')
    json['features']['userAndSessionManagement']['data']['settings']['all']['1.0']['radius']['1.0']['settings']['connectivity']['secondaryServer'].delete('secret')

    cfg = JSON.pretty_generate(json)
    cfg
  end

  cfg :ssh do
    exec true
    pre_logout 'logout'
  end
end
