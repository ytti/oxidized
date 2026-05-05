require 'nokogiri'

class PanOSXML < Oxidized::Model

  comment '! '

  prompt /^[\w.@:()-]+[#>]\s?$/

  cmd 'show config running' do |cfg|
    "<?xml version=\"1.0\"?>\n" +
    Nokogiri::XML(
        cfg.split("\n")[2..-2].join("\n")
    ).at('/response/result/config').to_xml(indent: 2)
  end

  cfg :ssh do
    post_login 'set cli pager off'
    post_login 'set cli op-command-xml-output on'
    post_login 'set cli config-output-format xml'
    pre_logout 'quit'
  end
end
