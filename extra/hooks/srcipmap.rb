### script in ~/config/oxidized/hook/srcipmap.rb ## or OXDIZED_HOME equivalent
###
### router.db:
### router1:1.1.1.1:cisco:c7200:10.10.10.1:somerole
### router2:2.2.2.2:juniper:mx80:10.10.10.2:wlc
### router3:3.3.3.3:juniper:mx2020:10.10.10.3:anotherrole
###
### config:
### source:
###   default: csv
###   csv:
###    file: "/Users/ytti/.config/oxidized/router.db"
###    delimiter: !ruby/regexp /:/
###    map:
###      name: 0
###      ip: 1
###      model: 2
### model_map:
###   juniper: junos
###   cisco: ios
### hooks:
###   somename:
###    type: srcipmap
###    events: ["source_node_transform"]
###
###
###
### Nodes BEFORE script:
### {name: "router1", ip: "1.1.1.1", model: "ios"}
### {name: "router2", ip: "2.2.2.2", model: "junos"}
### {name: "router3", ip: "3.3.3.3", model: "junos"
###
### Nodes AFTER script:
### {name: "router1", ip: "1.1.1.1", model: "ios"}
### {name: "router2", ip: "10.10.10.2", model: "junos"}
### {name: "router3", ip: "3.3.3.3", model: "junos"}

class SrcIpMap < Oxidized::Hook
  def run_hook(ctx)
    # node is the node[key] that we'd return without manipulation
    node = ctx.node

    ## node_raw is source specific, in CSV it is just the field number
    _platform = ctx.node_raw[3]
    oob_ip = ctx.node_raw[4]
    role = ctx.node_raw[5]

    ### the magic
    node[:ip] = oob_ip if role == 'wlc'

    ### remember to return the manipulated object, nil if you want to ignore loading node
    node
  end
end
