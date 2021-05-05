#!/usr/bin/env ruby

## contrib via https://github.com/ytti/oxidized/issues/67

require 'open-uri'
require 'net/https'
require 'json'
require 'time'

critical = false
pending = false
critical_nodes = []
pending_nodes = []
node_count = 0

url = ARGV[0] ||= "http://localhost:8888"
username = ARGV[1] ||= ""
password = ARGV[2] ||= ""
ssl_verify = ARGV[3] ||= true # pass false as argument in order to disable ssl verification
days_allowed_without_backups = ARGV[4] ||= "0"

json = JSON.load(open("#{url}/nodes.json", {http_basic_authentication: ["#{username}", "#{password}"], ssl_verify_mode: ssl_verify == "false" ? OpenSSL::SSL::VERIFY_NONE : OpenSSL::SSL::VERIFY_PEER}))
json.each do |node|
  if not node['last'].nil?
    if node['last']['status'] != 'success'
      critical_nodes << node['name']
      critical = true
    elsif node['last']['end'] && (DateTime.now - DateTime.strptime(node['last']['end'], '%Y-%m-%d %H:%M:%s')).to_i > days_allowed_without_backups.to_i
      critical_nodes << node['name']
      critical = true
    else
      node_count += 1
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
  puts "[OK] Backup of all #{node_count} nodes completed successfully."
  exit 0
end
