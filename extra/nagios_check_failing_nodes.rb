#!/usr/bin/env ruby

## contrib via https://github.com/ytti/oxidized/issues/67

require 'open-uri'
require 'json'

critical = false
critical_nodes = []

json = JSON.load(open("http://localhost:8888/nodes.json"))
json.each do |node|
  if node['last']['status'] != 'success'
    critical_nodes << node['name']
    critical = true
  end
end

if critical
  puts 'Unable to backup: ' + critical_nodes.join(' ')
  exit 2
else
  puts 'Backup of all nodes completed successfully.'
  exit 0
end
