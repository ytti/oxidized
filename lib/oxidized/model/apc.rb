class Apc < Oxidized::Model

  # For use with most APC PDUs supporting FTP

  cmd 'config.ini'

  cfg :ftp do
  end

end
