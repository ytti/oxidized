class Apc7922 < Oxidized::Model

  # Only tested on APC AP7922 PDUs, may work with others, but no guarantee.

  cmd 'config.ini'

  cfg :ftp do
  end

end
