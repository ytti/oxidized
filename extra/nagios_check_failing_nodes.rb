#!/usr/bin/env ruby

## contrib via https://github.com/ytti/oxidized/issues/67

require 'open-uri'
require 'json'

critical = false
pending = false
critical_nodes = []
pending_nodes = []

json = JSON.parse(open("http://localhost:8888/nodes.json").read)
json.each do |node|
  if not ARGV.empty?
    if ARGV[0] != node['name']
      next
    end
  end
  if not node['last'].nil?
    if node['last']['status'] != 'success'
      critical_nodes << node['name']
      critical = true
    end
  else
    pending_nodes << node['name']
    pending = true
  end
end

if critical
  puts '[CRIT] Unable to backup: ' + critical_nodes.join(',')
  exit 2
elsif pending
  puts '[WARN] Pending backup: ' + pending_nodes.join(',')
  exit 1
else
  if not ARGV.empty?
    puts '[OK] Backup of node ' + ARGV[0] + ' completed successfully.'
  else
    puts '[OK] Backup of all nodes completed successfully.'
  end
  exit 0
end
