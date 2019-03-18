class Cambium < Oxidized::Model
  cfg_cb = lambda do
    c_page = @m.click @m_page.link_with(text: "Configuration")
    u_page = @m.click c_page.link_with(text: "Unit Settings")
    cfg    = @m.click u_page.link_with(text: /\.cfg$/)
    cfg.body
  end

  cmd cfg_cb do |cfg|
    cfg.gsub! /"cfgUtcTimestamp":.*?,\n/, ''
    cfg
  end

  cfg :http do
    @main_page = "/main.cgi"
    define_singleton_method :login do
      @m_page = @m_page.form_with(action: "login.cgi") do |form|
        form.CanopyUsername = @node.auth[:username]
        form.CanopyPassword = @node.auth[:password]
      end.submit
    end
  end
end
