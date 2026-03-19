# Advanced dynamic model selection hook for Oxidized
# --------------------------------------------------
# This hook allows you to assign Oxidized models based on any device attributes
# (name, vendor, group, type, IP, etc.) using flexible rules defined in the config.
# It uses the `source_node_transform` event and works with any source (CSV, HTTP, SQL).
#
# The hook is designed to be generic: you can specify any field that exists in the
# node data after source mapping (see `map` section in the source configuration).
# Rules are evaluated in order; the first matching rule assigns its `model`.
#
# ⚠️ IMPORTANT: For the hook to load correctly:
#   - The filename must match the hook type (e.g., `modelrulesadvanced.rb`).
#   - The class name must be the CamelCase version of the filename without underscores
#     (e.g., filename `modelrulesadvanced.rb` → class `Modelrulesadvanced`).
#   - In the Oxidized config, specify `type: modelrulesadvanced` (the filename without .rb).
#
# ⚠️ DOCKER NOTE: This hook was developed and tested in a Docker container.
#   Ensure that your hooks directory inside the container is
#   `/home/oxidized/.config/oxidized/hook` (singular "hook"), not "hooks".
#   In docker-compose, mount your local hooks folder to this path, e.g.:
#   volumes:
#     - ./extra/hooks:/home/oxidized/.config/oxidized/hook
#
# Example scenario with NetBox:
#   Suppose your NetBox instance returns devices with the following data (simplified):
#     gw-001  | Mikrotik | RB750 | ro_ud  | 192.168.0.167/24
#     gw-002  | Mikrotik | RB750 | ro_ud  | 192.168.0.177/24
#     gw-003  | Mikrotik | RB750 | ro_bd  | 192.168.0.178/24
#     gw-004  | Mikrotik | RB750 | switch | 192.168.0.181/24
#     gw-005  | Cisco    | 2960  | switch | 192.168.0.179/24
#     gw-006  | Mikrotik | RB750 | switch | 192.168.0.180/24
#     gw-007  | Arista   | 3456  | ro_ud  | 192.168.0.190/24
#
#   Desired model assignment:
#     - gw-001 (exception by name) → asa
#     - MikroTik in group `switch` with IP 192.168.0.180/24 → eltex
#     - All other MikroTik → routeros
#     - Cisco switches → ios
#     - Arista devices → eos
#
# Example configuration (top-level in Oxidized config):
#   ---
#   username: oxidized_ssh_user
#   password: oxidized_ssh_password
#
#   hooks:
#     modelrulesadvanced:
#       type: modelrulesadvanced
#       events: [source_node_transform]
#       rules:
#         - description: "Exception: gw-001 uses ASA model"
#           name: gw-001
#           model: asa
#         - description: "Mikrotik switch with IP 192.168.0.180/24 uses eltex"
#           vendor: Mikrotik
#           group: switch
#           ip: 192.168.0.180/24
#           model: eltex
#         - description: "All other Mikrotik devices"
#           vendor: Mikrotik
#           model: routeros
#         - description: "Cisco switches"
#           vendor: Cisco
#           group: switch
#           model: ios
#         - description: "Arista devices"
#           vendor: Arista
#           model: eos
#
#   resolve_dns: false
#   interval: 3600
#   rest: 0.0.0.0:8888
#   log: /home/oxidized/.config/oxidized/logs/oxidized.log
#   debug: true   # optional – enables detailed logging from the hook
#
#   source:
#     default: http
#     http:
#       url: http://netbox.test/api/dcim/devices/?status=active&has_primary_ip=true
#       headers:
#         Authorization: Token YOUR_API_TOKEN
#       map:
#         name: name
#         vendor: device_type.manufacturer.name
#         type: device_type.model
#         group: role.slug
#         ip: primary_ip.address
#       secure: false
#       hosts_location: results
#       pagination: true
#       pagination_key_name: next
#
#   output:
#     default: file
#     file:
#       directory: "/home/oxidized/.config/oxidized/configs"
#
#   groups:
#     ro_ud: {}
#     ro_bd: {}
#     switch: {}
#
# How it works:
#   1. Oxidized loads node data from the source (NetBox) and applies the `map`.
#   2. For each node, the `source_node_transform` event is triggered.
#   3. This hook receives a context object `ctx` containing:
#        - `ctx.node` – the mapped node attributes (hash)
#        - `ctx.node_raw` – the original source record (useful for unmapped fields)
#   4. The hook iterates through the rules defined in `cfg.rules`.
#   5. For each rule, it checks that every specified key (except `model` and `description`)
#      matches the corresponding value in `ctx.node`. Comparison is case‑insensitive and
#      strips surrounding spaces.
#   6. The first matching rule assigns its `model` to `ctx.node[:model]`.
#   7. If no rule matches, the node's `model` remains unchanged.
#   8. The modified (or original) node is returned; returning `nil` would exclude the node.
#
# Notes:
#   - Rule order is crucial: place more specific rules (e.g., with IP or name) before generic ones.
#   - The `description` field is optional and only appears in debug logs.
#   - Any field present in `ctx.node` after mapping can be used as a match key.
#   - For HTTP sources (NetBox), you can access additional fields via `ctx.node_raw["field"]`.
#   - Debug logging requires `debug: true` in the global config.

class Modelrulesadvanced < Oxidized::Hook
  # Validate that the hook configuration contains a 'rules' array.
  def validate_cfg!
    raise KeyError, "hook.rules is required" unless cfg.has_key?("rules")
  end

  # Main hook method – called for each node during source_node_transform event.
  def run_hook(ctx)
    node = ctx.node
    rules = cfg.rules || []

    matched_model = nil
    rules.each_with_index do |rule, idx|
      match = true
      rule.each do |key, value|
        next if key == "model" || key == "description"
        # Retrieve the corresponding value from the node (symbol or string key)
        node_value = node[key.to_sym] || node[key.to_s]
        if node_value.to_s.strip.downcase != value.to_s.strip.downcase
          match = false
          break
        end
      end
      if match
        matched_model = rule["model"]
        desc = rule["description"] ? " (#{rule['description']})" : ""
        logger.debug "ModelRulesAdvanced: rule #{idx+1}#{desc} matched -> #{matched_model}"
        break
      end
    end

    if matched_model
      old_model = node[:model] || node["model"]
      node[:model] = matched_model
      logger.debug "ModelRulesAdvanced: changed model from #{old_model.inspect} to #{matched_model.inspect}"
    else
      logger.debug "ModelRulesAdvanced: no rule matched, keeping existing model: #{node[:model] || node['model'].inspect}"
    end

    node
  end
end
