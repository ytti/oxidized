# UFiber #
class UFiber < Oxidized::Model
  # UFiber #
  prompt /.+@.+:~\$\s/

  cmd 'cat /tmp/config'
  cmd 'rm /tmp/config'

  cmd :all do |cfg|
    cfg.lines.to_a[1..-3].join
  end

  cfg :ssh do
    post_login 'curl -s --output /dev/null --location --insecure '\
                '--data \''\
                "username=#{@node.auth[:username]}&" \
                "password=#{@node.auth[:password]}' " \
                '--cookie-jar /tmp/cookies https://localhost'
    post_login 'curl -s --output /dev/null --location --insecure '\
                '--cookie /tmp/cookies '\
                'https://localhost/api/edge/config/save.json'
    post_login 'curl -s --location --insecure '\
                '--cookie /tmp/cookies '\
                'https://localhost/files/config/ '\
                '| base64 > /tmp/config'
    pre_logout 'exit'
  end
end
