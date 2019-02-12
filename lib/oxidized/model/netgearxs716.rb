class NetgearXS716 < Oxidized::Model
  cfg_cb = lambda do
    c = @m.get("/upload_download/startup-config")
    c.body
  end

  cmd cfg_cb do |cfg|
    cfg
  end

  cmd :secret do |cfg|
    cfg.gsub!(/password (\S+)/, 'password <hidden>')
    cfg.gsub!(/encrypted (\S+)/, 'encrypted <hidden>')
    cfg
  end

  cfg :http do
    @main_page = "/base/main_login.html"
    define_singleton_method :login do
      @m_page = @m.post("/base/cheetah_login.html", 'pwd' => @node.auth[:password])
    end
  end
end
