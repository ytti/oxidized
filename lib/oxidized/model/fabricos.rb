class FabricOS < Oxidized::Model

  # Brocade Fabric OS model #
  ## FIXME: Only ssh exec mode support, no telnet, no ssh screenscraping

  prompt /^([\w]+:+[\w]+[>]\s)$/
  comment  '# '

  cmd 'chassisShow' do |cfg|
    comment cfg
  end

  cmd 'configShow -all' do |cfg|
    cfg
  end

  cfg :ssh do
    exec true  # don't run shell, run each command in exec channel
  end

end
