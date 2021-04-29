class GrandStream < Oxidized::Model
  cmd "/cgi-bin/dologin?password=%<password>s" do |cfg| # rubocop:disable Style/FormatStringToken
    sid = JSON.parse(cfg)["body"]["sid"]
    cmd "/cgi-bin/download_cfg?sid=#{sid}"
  end

  cfg :http do
  end
end
