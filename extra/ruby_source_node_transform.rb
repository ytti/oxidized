# ruby_source_node_transform.rb
#
# Example ruby hook for the source_node_transform event.
#
# This hook runs for every node loaded from the source (JSON, HTTP, CSV, SQL)
# before it is added to the node list. It can:
#   - Override node attributes (e.g. pick a more specific model name)
#   - Return nil to exclude the node entirely
#
# The hook receives a HookContext with:
#   ctx.node     - Hash of parsed node attributes built from the source
#                  mapping (e.g. { name:, ip:, model:, group:, vars: }).
#                  This is the value being chained: return the (possibly
#                  modified) hash to pass it to the next hook in sequence.
#   ctx.node_raw - The original source record before mapping:
#                    JSON/HTTP source  -> Ruby Hash  (string keys)
#                    CSV source        -> Array of field strings
#                    SQL source        -> Hash of column values
#   ctx.binding  - Ruby Binding captured at the call site (advanced use)
#
# Return value:
#   Hash  - node attributes to use (may be the original or a modified copy)
#   nil   - exclude this node from the node list
#
# ============================================================================
# Use case 1: JSON / HTTP source with vendor + platform fields
# ============================================================================
#
# Many inventory systems (NetBox, LibreNMS, custom CMDBs) expose both a
# vendor name and an OS/platform identifier. Oxidized's source mapping can
# only map a single field to `model`, but this hook lets you pick the right
# oxidized model based on the combination of vendor and platform.
#
# Example source node (JSON/HTTP):
#   {
#     "name":     "core-sw-01",
#     "ip":       "10.0.0.1",
#     "vendor":   "cisco",
#     "platform": "NX-OS"
#   }
#
# Oxidized config (maps vendor -> model as the default):
#   source:
#     http:
#       url: https://inventory.example.com/api/nodes
#       map:
#         name:  name
#         ip:    ip
#         model: vendor
#
#   hooks:
#     node_transform:
#       type: ruby
#       events: [source_node_transform]
#       file: /etc/oxidized/hooks/ruby_source_node_transform.rb
#
# The hook below overrides the model that was set from `vendor` when the
# platform identifies a more specific oxidized model. All other vendors/
# platforms pass through unchanged.
#
# ============================================================================
# Use case 2: model-specific IP field selection
# ============================================================================
#
# Some devices expose a dedicated management IP (mgmt_ip) while others use
# an out-of-band IP (oob_ip). Oxidized's source map can only point `ip` at
# one field globally, but this hook lets each model pick the right one.
#
# Example source nodes (JSON/HTTP):
#   { "name": "core-sw-01", "model": "iosxe", "mgmt_ip": "10.0.0.1", "oob_ip": "" }
#   { "name": "edge-rt-01", "model": "junos", "mgmt_ip": "",          "oob_ip": "10.0.1.1" }
#
# Oxidized config (ip field is not mapped at source level; hook sets it):
#   source:
#     http:
#       url: https://inventory.example.com/api/nodes
#       map:
#         name:  name
#         model: model
#
#   hooks:
#     node_transform:
#       type: ruby
#       events: [source_node_transform]
#       file: /etc/oxidized/hooks/ruby_source_node_transform.rb

PLATFORM_MODEL = {
  # Cisco platforms
  "IOS"    => "ios",
  "IOS-XE" => "iosxe",
  "IOS-XR" => "iosxr",
  "NX-OS"  => "nxos",
  # Juniper platforms
  "Junos"  => "junos",
  "JunOS"  => "junos",
  "EX"     => "junos"
  # Add further mappings as needed
}.freeze

# Models that reach oxidized via the out-of-band network; all others use mgmt_ip.
OOB_MODELS = %w[junos juniper].freeze

def source_node_transform(ctx)
  # Uncomment to exclude nodes flagged as inactive in the source:
  # return nil unless ctx.node_raw["active"]

  node = ctx.node

  # --- Use case 1: refine model from platform field ---
  platform = ctx.node_raw["platform"].to_s
  if (model = PLATFORM_MODEL[platform])
    node = node.merge(model: model)
  end

  # --- Use case 2: pick IP from model-specific field ---
  # If the source mapping did not set an ip (or set it to blank), derive it
  # from the field that matches this model's access method.
  if node[:ip].to_s.empty?
    ip = if OOB_MODELS.include?(node[:model].to_s.downcase)
           ctx.node_raw["oob_ip"].to_s
         else
           ctx.node_raw["mgmt_ip"].to_s
         end
    node = node.merge(ip: ip) unless ip.empty?
  end

  node
end
