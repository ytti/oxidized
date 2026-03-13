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
    cfg.gsub! /^# Timestamp:.*$/, ''
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
