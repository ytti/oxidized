# ~/.config/oxidized/source/zabbix.rb
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
        unless @cfg.url && @cfg.token && @cfg.template
          raise NoConfig, 'Please set source.zabbix.url, token and template'
        end

        # Which macros you care about
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

        ### Step 1: Get the base template ID for your named template
        tpl = rpc('template.get',
                  { filter: { host: [@cfg.template] },
                    output: ['templateid'] },
                  token).first or return []
        tpl_id = tpl['templateid']

        ### Step 2: Fetch all hosts linked to that template
        hosts = rpc('host.get',
                    { templateids:           [tpl_id],
                      output:                ['hostid','host'],
                      filter:                { status: '0' },
                      selectParentTemplates: ['templateid'] },
                    token) || []
        return [] if hosts.empty?

        # Pre‐fetch interfaces
        hostids = hosts.map { |h| h['hostid'] }
        ifaces  = rpc('hostinterface.get',
                      { hostids: hostids,
                        output:  ['hostid','useip','ip','dns'] },
                      token) || []

        nodes = []

        hosts.each do |h|
          hid = h['hostid']

          # 2a) Host’s direct templates
          direct_tpls = (h['parentTemplates'] || []).map { |pt| pt['templateid'] }

          # 2b) For each direct template, fetch its parents
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

          # Build the full ID list: host + direct tpl + their parents
          id_list = [hid] | all_tpls

          ### Step 3: Pull **all** macros for those IDs
          macros = rpc('usermacro.get',
                       { output:  'extend',
                         hostids: id_list,
                         secrets: false },
                       token) || []

          # Map macros into a hash
          macro_map = {}
          macros.each do |m|
            next unless @needed[m['macro'].to_s]
            key = @needed[m['macro'].to_s]
            macro_map[key] = node_var_interpolate(m['value'].to_s)
          end

          # Build the node
          node = {
            name: h['host'],
            ip:   pick_ip(ifaces.select { |i| i['hostid'] == hid })
          }.merge(macro_map)

          # Only set enable if non‐empty
          if node[:enable] && !node[:enable].strip.empty?
            node[:vars] = { enable: node.delete(:enable) }
          end

          node[:model] = node[:model].to_s if node[:model]
          nodes << node
        end

        nodes
      end

      private

      # pick the first non-empty IP
      def pick_ip(if_list)
        ips = if_list.map { |i| i['ip'].to_s }.reject(&:empty?)
        ips.first || ''
      end

      # JSON-RPC helper, always returns an Array
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
