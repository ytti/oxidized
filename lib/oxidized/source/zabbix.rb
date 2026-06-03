# ~/.config/oxidized/source/zabbix.rb
#
#  ▸ Hosts can be selected by the template named in source.zabbix.template
#    or by Zabbix tags configured in source.zabbix.tags
#  ▸ Template macros fetched via usermacro.get hostids:[TEMPLATE_ID] quirk
#  ▸ Host-level overrides win

require 'net/http'
require 'json'
require 'uri'
require 'openssl'

module Oxidized
  module Source
    class Zabbix < Source
      class NoConfig < OxidizedError; end

      def initialize
        super
        @cfg = Oxidized.config.source.zabbix
        unless @cfg.url && @cfg.token && (@cfg.template || @cfg.tags)
          raise NoConfig, 'Please set source.zabbix.url, token and template or tags'
        end

        @needed = {
          @cfg.map.username.to_s => :username,
          @cfg.map.password.to_s => :password,
          @cfg.map.model.to_s    => :model,
          @cfg.vars_map.group.to_s  => :group,
          @cfg.vars_map.enable.to_s => :enable
        }
      end

      def load(_ = nil)
        token = @cfg.token
        params = host_get_params(token)
        return [] unless params

        hosts = rpc('host.get', params, token) || []
        return [] if hosts.empty?

        hostids = hosts.map { |h| h['hostid'] }
        ifaces  = rpc('hostinterface.get',
                      { hostids: hostids,
                        output:  ['hostid', 'useip', 'ip', 'dns'] },
                      token) || []

        nodes = []

        hosts.each do |h|
          hid = h['hostid']

          direct_tpls = (h['parentTemplates'] || []).map { |pt| pt['templateid'] }

          all_tpls = direct_tpls.dup
          direct_tpls.each do |tid|
            parents = rpc('template.get',
                          { templateids:           [tid],
                            output:                ['templateid'],
                            selectParentTemplates: ['templateid'] },
                          token).first['parentTemplates'] rescue []
            parents.map { |pt| pt['templateid'] }.each do |pid|
              all_tpls << pid unless all_tpls.include?(pid)
            end
          end

          id_list = [hid] | all_tpls

          macros = rpc('usermacro.get',
                       { output:  'extend',
                         hostids: id_list,
                         secrets: false },
                       token) || []

          macro_map = {}
          macros.each do |m|
            next unless @needed[m['macro'].to_s]

            key = @needed[m['macro'].to_s]
            macro_map[key] = node_var_interpolate(m['value'].to_s)
          end

          node = {
            name: h['host'],
            ip:   pick_ip(ifaces.select { |i| i['hostid'] == hid })
          }.merge(macro_map)

          if node[:enable] && !node[:enable].strip.empty?
            node[:vars] = { enable: node.delete(:enable) }
          end

          node[:model] = node[:model].to_s if node[:model]
          nodes << node
        end

        nodes
      end

      private

      def host_get_params(token)
        params = {
          output:                ['hostid', 'host'],
          filter:                { status: '0' },
          selectParentTemplates: ['templateid']
        }

        if @cfg.template
          tpl = rpc('template.get',
                    { filter: { host: [@cfg.template] },
                      output: ['templateid'] },
                    token).first
          return nil unless tpl

          params[:templateids] = [tpl['templateid']]
        end

        params[:tags] = tag_filters if @cfg.tags
        params
      end

      def tag_filters
        array_config(@cfg.tags).map { |tag| hash_config(tag) }
      end

      def array_config(value)
        value.is_a?(Array) ? value : [value]
      end

      def hash_config(config)
        config.each_with_object({}) do |(key, value), hash|
          hash[key.to_s] = value
        end
      end

      def pick_ip(if_list)
        ips = if_list.map { |i| i['ip'].to_s }.reject(&:empty?)
        ips.first || ''
      end

      def rpc(method, params, token)
        uri  = URI.parse(@cfg.url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')
        body    = { jsonrpc: '2.0', method: method, params: params, id: 1 }.to_json
        headers = {
          'Content-Type'  => 'application/json-rpc',
          'Authorization' => "Bearer #{token}"
        }
        resp   = http.post(uri.request_uri, body, headers)
        parsed = JSON.parse(resp.body)
        return [] if parsed['error']

        parsed['result'] || []
      rescue StandardError => e
        Oxidized.logger.error "Zabbix RPC(#{method}): #{e.class} #{e.message}"
        []
      end
    end
  end
end
