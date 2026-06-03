# ~/.config/oxidized/source/zabbix.rb
#
# Hosts can be selected by template, templateids, tags, searchInventory, or filter.
# Template and host macros are fetched through usermacro.get.
# Host-level macro values override template macro values.

require "net/http"
require "net/https"
require "json"
require "uri"
require "openssl"

module Oxidized
  module Source
    class Zabbix < Source
      class NoConfig < OxidizedError; end

      def initialize
        super
        @cfg = Oxidized.config.source.zabbix
        @template_cache = {}
      end

      def setup
        if @cfg.empty?
          Oxidized.asetus.user.source.zabbix.url = "https://zabbix.example.com/api_jsonrpc.php"
          Oxidized.asetus.user.source.zabbix.token = "zabbix_api_token"
          Oxidized.asetus.user.source.zabbix.template = "Template Oxidized"
          Oxidized.asetus.user.source.zabbix.map.username = "{$OXIDIZED_USERNAME}"
          Oxidized.asetus.user.source.zabbix.map.password = "{$OXIDIZED_PASSWORD}"
          Oxidized.asetus.user.source.zabbix.map.model = "{$OXIDIZED_MODEL}"
          Oxidized.asetus.user.source.zabbix.vars_map.group = "{$OXIDIZED_GROUP}"
          Oxidized.asetus.save :user
          raise NoConfig, "No source zabbix config, edit #{Oxidized::Config.configfile}"
        end

        unless @cfg.url && @cfg.token
          raise NoConfig, "Please set source.zabbix.url and token"
        end

        return if host_selector_configured?

        raise NoConfig, "Please set one of source.zabbix.template, templateids, tags, searchInventory or filter"
      end

      def load(node_want = nil)
        nodes = []
        hosts = rpc("host.get", host_params(node_want))
        return nodes if hosts.empty?

        interfaces = interfaces_for(hosts)
        hosts.each do |host|
          raw = normalize_host(host, interfaces.fetch(host["hostid"], []))
          node = map_node(raw)
          node = Oxidized.hooks.source_node_transform(node: node, node_raw: raw, context: self)
          nodes << node unless node.nil?
        end

        nodes
      end

      private

      def host_selector_configured?
        @cfg.has_key?("template") || @cfg.has_key?("templateids") || @cfg.has_key?("tags") ||
          @cfg.has_key?("searchInventory") || @cfg.has_key?("filter")
      end

      def host_params(node_want)
        params = {
          output: ["hostid", "host", "name"],
          filter: host_filter(node_want),
          selectParentTemplates: ["templateid"]
        }

        templateids = configured_templateids
        params[:templateids] = templateids unless templateids.empty?

        tags = configured_tags
        params[:tags] = tags unless tags.empty?

        search_inventory = configured_search_inventory
        params[:searchInventory] = search_inventory unless search_inventory.empty?

        params
      end

      def host_filter(node_want)
        filter = @cfg.has_key?("filter") ? hash_config(@cfg.filter) : { "status" => "0" }
        filter["host"] = node_want if node_want
        filter
      end

      def configured_templateids
        templateids = []
        templateids.concat array_config(@cfg.templateids) if @cfg.has_key? "templateids"
        templateids.concat templateids_by_name(array_config(@cfg.template)) if @cfg.has_key? "template"
        templateids.map(&:to_s).uniq
      end

      def templateids_by_name(names)
        return [] if names.empty?

        params = { filter: { host: names }, output: ["templateid"] }
        rpc("template.get", params).map { |template| template["templateid"] }
      end

      def configured_tags
        return [] unless @cfg.has_key? "tags"

        array_config(@cfg.tags).map { |tag| hash_config(tag) }
      end

      def configured_search_inventory
        return {} unless @cfg.has_key? "searchInventory"

        hash_config(@cfg.searchInventory)
      end

      def interfaces_for(hosts)
        hostids = hosts.map { |host| host["hostid"] }
        params = { hostids: hostids, output: ["hostid", "useip", "ip", "dns", "main"] }
        rpc("hostinterface.get", params).group_by { |interface| interface["hostid"] }
      end

      def normalize_host(host, interfaces)
        {
          "hostid" => host["hostid"],
          "host" => host["host"],
          "name" => host["name"],
          "ip" => pick_address(interfaces),
          "interfaces" => interfaces,
          "macros" => macros_for(host),
          "raw" => host
        }
      end

      def map_node(raw)
        node = { name: raw["host"], ip: raw["ip"] }

        map_config(@cfg.map).each do |key, want|
          node[key.to_sym] = node_var_interpolate(lookup(raw, want))
        end

        map_vars(raw).each do |key, value|
          node[key.to_sym] = value if key == "group"
          node[:vars] ||= {}
          node[:vars][key] = value unless key == "group"
        end

        node[:model] = map_model node[:model] if node.has_key? :model
        node[:group] = map_group node[:group] if node.has_key? :group
        node.delete_if { |_key, value| value.nil? || value == "" || value == {} }
      end

      def map_vars(raw)
        vars = {}
        return vars unless @cfg.has_key? "vars_map"

        @cfg.vars_map.each do |key, macro|
          value = node_var_interpolate(lookup(raw, macro))
          vars[key.to_s] = value unless value.nil? || value == ""
        end

        vars
      end

      def lookup(raw, want)
        path = want.to_s
        return raw["macros"][path] if path.start_with?("{") && path.end_with?("}")

        string_navigate_object(raw, path)
      end

      def map_config(config)
        return {} unless config

        config.each_with_object({}) do |(key, value), hash|
          hash[key.to_s] = value
        end
      end

      def macros_for(host)
        ids = templateids_for(host).reverse + [host["hostid"]]
        params = { output: ["hostid", "macro", "value"], hostids: ids, secrets: false }
        macros = rpc("usermacro.get", params)
        macros_by_host = macros.group_by { |macro| macro["hostid"] }

        ids.each_with_object({}) do |id, values|
          macros_by_host.fetch(id, []).each do |macro|
            values[macro["macro"]] = macro["value"]
          end
        end
      end

      def templateids_for(host)
        queue = (host["parentTemplates"] || []).map { |template| template["templateid"] }
        templateids = queue.dup

        until queue.empty?
          parent_templateids(queue.shift).each do |templateid|
            next if templateids.include? templateid

            templateids << templateid
            queue << templateid
          end
        end

        templateids
      end

      def parent_templateids(templateid)
        @template_cache[templateid] ||= rpc("template.get", template_params(templateid)).flat_map do |template|
          template.fetch("parentTemplates", []).map { |parent| parent["templateid"] }
        end
      end

      def template_params(templateid)
        {
          templateids: [templateid],
          output: ["templateid"],
          selectParentTemplates: ["templateid"]
        }
      end

      def pick_address(interfaces)
        interface = interfaces.find { |entry| entry["main"].to_s == "1" } || interfaces.first || {}
        address = interface["useip"].to_s == "0" ? interface["dns"] : interface["ip"]
        address.to_s
      end

      def rpc(method, params)
        uri = URI.parse(@cfg.url)
        response = http(uri).request(request(uri, method, params))
        return rpc_http_error(method, response) unless response.is_a? Net::HTTPSuccess

        parsed = JSON.parse(response.body)
        return rpc_zabbix_error(method, parsed["error"]) if parsed["error"]

        parsed["result"] || []
      rescue StandardError => e
        Oxidized.logger.error "Zabbix RPC(#{method}): #{e.class} #{e.message}"
        []
      end

      def http(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE if @cfg.has_key?("secure") && !@cfg.secure
        http.read_timeout = Integer(@cfg.read_timeout) if @cfg.has_key? "read_timeout"
        http
      end

      def request(uri, method, params)
        request = Net::HTTP::Post.new(uri.request_uri, headers)
        request.body = { jsonrpc: "2.0", method: method, params: params, id: 1 }.to_json
        request
      end

      def headers
        {
          "Content-Type" => "application/json-rpc",
          "Authorization" => "Bearer #{@cfg.token}"
        }
      end

      def rpc_http_error(method, response)
        Oxidized.logger.error "Zabbix RPC(#{method}): HTTP #{response.code} #{response.message}"
        []
      end

      def rpc_zabbix_error(method, error)
        Oxidized.logger.error "Zabbix RPC(#{method}): #{error}"
        []
      end

      def hash_config(config)
        config.each_with_object({}) do |(key, value), hash|
          hash[key.to_s] = value
        end
      end

      def array_config(value)
        value.is_a?(Array) ? value : [value]
      end
    end
  end
end
