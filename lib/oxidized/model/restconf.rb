class Restconf < Oxidized::Model

  cmd :all do |cfg|
    cfg.gsub! /^(\s+"secret":) ".*"$/, '\\1 "<redacted>"'
    cfg.cut_both
  end

  cmd '/restconf/data/Cisco-IOS-XE-native:native'

  cfg :http do
    @username = @node.auth[:username]
    @password = @node.auth[:password]
    @headers['Content-Type'] = 'application/yang-data+json'
    @headers['Accept'] = 'application/yang-data+json'
    @secure = true
  end
end
