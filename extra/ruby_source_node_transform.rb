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
#   ctx.node_attrs  - Hash of parsed node attributes built from the source
#                     mapping (e.g. { name:, ip:, model:, group:, vars: }).
#                     This is the value being chained: return the (possibly
#                     modified) hash to pass it to the next hook in sequence.
#   ctx.raw_node    - The original source record before mapping:
#                       JSON/HTTP source  -> Ruby Hash  (string keys)
#                       CSV source        -> Array of field strings
#                       SQL source        -> Hash of column values
#   ctx.binding     - Ruby Binding captured at the call site (advanced use)
#
# Return value:
#   Hash  - node_attrs to use (may be the original or a modified copy)
#   nil   - exclude this node from the node list
#
# ============================================================================
# Use case: JSON / HTTP source with vendor + platform fields
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
# Oxidized config (maps vendor → model as the default):
#   source:
#     http:
#       url: https://inventory.example.com/api/nodes
#       map:
#         name:  name
#         ip:    ip
#         model: vendor
#
#   hooks:
#     model_by_platform:
#       type: ruby
#       events: [source_node_transform]
#       file: /etc/oxidized/hooks/ruby_source_node_transform.rb
#
# The hook below overrides the model that was set from `vendor` when the
# platform identifies a more specific oxidized model. All other vendors/
# platforms pass through unchanged.

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

def source_node_transform(ctx)
  # Uncomment to exclude nodes flagged as inactive in the source:
  # return nil unless ctx.raw_node["active"]

  platform = ctx.raw_node["platform"].to_s
  model    = PLATFORM_MODEL[platform]

  # Return the node_attrs with an overridden model if we have a mapping,
  # otherwise return node_attrs unchanged (vendor-based model stays).
  if model
    ctx.node_attrs.merge(model: model)
  else
    ctx.node_attrs
  end
end
