require 'mechanize'

class PfSenseHttps < Oxidized::Model
  cfg_cb = lambda do
    main_page = "/index.php"
    m = Mechanize.new

    m.agent.http.verify_mode = Oxidized.config.input.http.ssl_verify? ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
    # https port might be something else than 443, so allow that to be configured.
    port = vars(:https_port) || 443
    url = URI::HTTPS.build host: @node.ip, path: main_page, port: port

    m_page = m.get(url.to_s)
    form = m_page.forms.first
    form.usernamefld = @username
    form.passwordfld = @password
    form.click_button

    b_page = m.get('/diag_backup.php')
    form = b_page.form_with(action: '/diag_backup.php')
    form.backuparea = ''
    cfg = form.click_button(form.button_with(name: 'download'))
    cfg.body
  end

  cmd :secret do |cfg|
    cfg.gsub! /(\s+<bcrypt-hash>).+?(<\/bcrypt-hash>)/, '\\1<secret hidden>\\2'
    cfg.gsub! /(\s+<password>).+?(<\/password>)/, '\\1<secret hidden>\\2'
    cfg.gsub! /(\s+<lighttpd_ls_password>).+?(<\/lighttpd_ls_password>)/, '\\1<secret hidden>\\2'
    cfg
  end

  cmd cfg_cb do |cfg|
    cfg.gsub! /\s<revision>\s*<time>\d*<\/time>\s*.*\s*.*\s*<\/revision>/, ''
    cfg.gsub! /\s<last_rule_upd_time>\d*<\/last_rule_upd_time>/, ''
    cfg
  end

  cfg :http do
    @username = @node.auth[:username]
    @password = @node.auth[:password]
    @secure = true
  end
end
