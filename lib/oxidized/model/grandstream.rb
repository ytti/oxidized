module Oxidized
  module Models
    # Represents the GrandStream model.
    #
    # Handles configuration retrieval and processing for GrandStream devices.

    class GrandStream < Oxidized::Models::Model
      using Refinements

      cmd "/cgi-bin/dologin?password=%<password>s" do |cfg| # rubocop:disable Style/FormatStringToken
        sid = JSON.parse(cfg)["body"]["sid"]
        cmd "/cgi-bin/download_cfg?sid=#{sid}"
      end

      cfg :http do
      end
    end
  end
end
