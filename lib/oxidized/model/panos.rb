module Oxidized
  module Models
    # # PanOS API
    #
    # Backup Palo Alto XML configuration via the HTTP API. Works for PanOS and Panorama.
    #
    # Logs in using username and password and fetches an API key.
    #
    # ## Requirements
    #
    # - Create a user with a `Superuser (read-only)` admin role in Panorama or PanOS
    # - Make sure the `nokogiri` gem is installed with your oxidized host
    #
    # ## Configuration
    #
    # Make sure the following is configured in the oxidized config:
    #
    # ```yaml
    # # allow ssl host name verification
    # resolve_dns: false
    # input:
    #   default: ssh, http
    #   http:
    #     secure: true
    #     ssl_verify: true
    #
    # # model specific configuration
    # #model:
    # #  panos_api:
    # ```

    class PanOS < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # PaloAlto PAN-OS model #

      comment '! '

      prompt /^[\w.@:()-]+>\s?$/

      cmd :all do |cfg|
        cfg.each_line.to_a[2..-3].join
      end

      cmd 'show system info' do |cfg|
        cfg.gsub! /^(up)?time: .*$/, ''
        cfg.gsub! /^app-.*?: .*$/, ''
        cfg.gsub! /^av-.*?: .*$/, ''
        cfg.gsub! /^threat-.*?: .*$/, ''
        cfg.gsub! /^wildfire-.*?: .*$/, ''
        cfg.gsub! /^wf-private.*?: .*$/, ''
        cfg.gsub! /^device-dictionary-version.*?: .*$/, ''
        cfg.gsub! /^device-dictionary-release-date.*?: .*$/, ''
        cfg.gsub! /^url-filtering.*?: .*$/, ''
        cfg.gsub! /^global-.*?: .*$/, ''
        comment cfg
      end

      cmd 'show config running' do |cfg|
        cfg
      end

      cfg :ssh do
        post_login 'set cli pager off'
        pre_logout 'quit'
      end
    end
  end
end
