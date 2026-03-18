### script in ~/config/oxidized/hook/modelrules.rb ## or OXDIZED_HOME equivalent
###
### router.db:
### router1:1.1.1.1:routeros::mikrotik
### router2:2.2.2.2:ios:switch:cisco
### router3:3.3.3.3:routeros:switch:mikrotik
###
### config:
### source:
###   default: csv
###   csv:
###     file: "/Users/ytti/.config/oxidized/router.db"
###     delimiter: !ruby/regexp /:/
###     map:
###       name: 0
###       ip: 1
###       model: 2
###       group: 3
### hooks:
###   somename:
###     type: modelrules
###     events: ["source_node_transform"]
###     rules:
###        - vendor: mikrotik
###          group: switch
###          model: eltex
###
### Nodes BEFORE script:
### {name: "router1", ip: "1.1.1.1", model: "routeros", group: ""}
### {name: "router2", ip: "2.2.2.2", model: "ios", group: "switch"}
### {name: "router3", ip: "3.3.3.3", model: "routeros", group: "switch"}
###
### Nodes AFTER script:
### {name: "router1", ip: "1.1.1.1", model: "routeros", group: ""}
### {name: "router2", ip: "2.2.2.2", model: "ios", group: "switch"}
### {name: "router3", ip: "3.3.3.3", model: "eltex", group: "switch"}
class ModelRules < Oxidized::Hook
  def validate_cfg!
    raise KeyError, 'hook.rules is required' unless cfg.has_key?('rules')
  end

  def run_hook(ctx)
    # node is the node[key] that we'd return without manipulation
    node = ctx.node ## e.g. node[:ip], node[:model] - what ever config maps

    ## node_raw is source specific, in CSV it is just the field number, in HTTP it is JSON
    vendor = ctx.node_raw[4]

    cfg.rules.each do |rule|
      node[:model] = rule['model'] if node[:group] == rule['group'] && vendor == rule['vendor']
    end

    node
  end
end
