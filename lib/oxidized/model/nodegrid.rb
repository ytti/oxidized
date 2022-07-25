class Nodegrid < Oxidized::Model

  prompt /(?<!@)\[(.*?\s\/)\]#/
  comment  '# '

  cmd 'show system/about/' do |cfg|
    comment cfg # Show System details, Model, Software Version
  end

  cmd 'show settings/license/' do |cfg|
    comment cfg # Show License information
  end

  cmd 'export_settings settings/ --plain-password' do |cfg|
    cfg # Print all system config including keys to be importable via import_settings function
  end

  cfg :ssh do
    pre_logout 'exit'
  end

end
