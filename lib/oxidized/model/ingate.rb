class Ingate < Oxidized::Model
  using Refinements

  cfg_cb = lambda do
    cfg = @m.post(
      @main_url,
      {
        'page'                                      => 'save',
        'db.webgui.testmode/1/timelimit'            => '30',
        'db.webgui.testmode/__KEEP_ROWS_ALIVE'      => '1',
        'db.webgui.pending_apply/1/verbosity'       => 'always',
        'db.webgui.pending_apply/__KEEP_ROWS_ALIVE' => '1',
        'action.admin.download_config_cli'          => 'Save config to CLI file',
        'upload.config_file;filename=type'          => 'application/octet-stream',
        'upload.clicmd_file;filename;type'          => 'application/octet-stream',
        'security'                                  => '',
        'got_complete_form'                         => 'yes'
      },
      'Accept' => 'application/x-config-database'
    )
    cfg.body
  end

  cmd cfg_cb do |cfg|
    cfg.gsub(/^# Timestamp:.*$/, '')
  end

  cmd :secret do |cfg|
    # Private keys: any *key field whose quoted value is a PEM private key block
    # (the value spans multiple lines).
    cfg.gsub!(/\b([a-z_]*key)="-----BEGIN [A-Z ]*PRIVATE KEY-----.*?-----END [A-Z ]*PRIVATE KEY-----"/m,
              '\1="<secret hidden>"')
    # Ingate spreads credentials across many fields. Match by suffix so we cover
    # them all (e.g. trunkuserpassword, snmppassword, radiussecret,
    # configencpassphrase, xauth_psk, eabhmackey, api_token) without touching
    # lookalikes such as passwordtimeout or enable_psk_rw.
    cfg.gsub!(/\b([a-z_]*(?:password|secret|passphrase|psk|hmackey|api_token|authtoken))=(?:"[^"]*"|\S+)/,
              '\1=<secret hidden>')
    cfg.gsub!(/\bcommunity=(?:"[^"]*"|\S+)/, 'community=<secret hidden>')
    cfg
  end

  cfg :http do
    @secure = true
    @main_page = "/"
    define_singleton_method :login do
      @main_url = URI::HTTP.build host: @node.ip, path: @main_page
      @m.post(
        @main_url,
        {
          'security_user'     => @node.auth[:username],
          'security_password' => @node.auth[:password],
          'page'              => 'login',
          'goal'              => 'save',
          'got_complete_form' => 'yes',
          'security'          => ''
        }
      )
    end
  end
end
