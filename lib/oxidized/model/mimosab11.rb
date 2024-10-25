module Oxidized
  module Models
    begin
      # @!visibility private
      # Mechanize has to be intialized here as the login needs a POST request
      require "mechanize"
    rescue LoadError
      # @!visibility private
      # Oxidized requires mechanize
      raise Oxidized::OxidizedError, "mechanize not found: sudo gem install mechanize"
    end

    class Mimosab11 < Oxidized::Models::Model
      using Refinements
      # @!visibility private
      # Callback cfg_cb function to login(POST) then get(GET) the configuration
      cfg_cb = lambda do
        @e = Mechanize.new
        # @!visibility private
        # Set login query endpoint(lqe) and login POST data(lqp)
        lqe = "https://#{@node.ip}/?q=index.login&mimosa_ajax=1"
        lgp = { "username" => "configure", "password" => @password }
        # @!visibility private
        # Set get request endpoint(gc) for config
        gc = "https://#{@node.ip}/?q=preferences.configure&mimosa_action=download"
        # @!visibility private
        # Not to verify self signed
        @e.verify_mode = 0
        @e.post(lqe, lgp)
        cfg = @e.get(gc)
        cfg.body
      end

      cmd cfg_cb do |cfg|
        cfg
      end

      cfg :http do
        @username = @node.auth[:username]
        @password = @node.auth[:password]
      end
    end
  end
end
