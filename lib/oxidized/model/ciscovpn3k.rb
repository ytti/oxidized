class CiscoVPN3k < Oxidized::Model
  # Used in Cisco VPN3000 concentrators
  # it have buggy code 227 reply with whitespace before trailing bracket
  # "227 Passive mode OK (172,16,0,9,4,9 )"
  # so use active ftp if you can. Or patch net/ftp

  cmd 'CONFIG'

  cfg :ftp do
  end
end
