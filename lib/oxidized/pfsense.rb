class PfSense < Oxidized::Model
  
  comment  '# '
  
  
  #add a comment in the final conf
  def add_comment comment
    "\n###### #{comment} ######\n" 
  end

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end
  
  #show the persistent configuration
  pre do
    cfg = add_comment 'Configuration'
    cfg += cmd 'cat /cf/conf/config.xml'    
  end
  

  cfg :ssh do
    exec true
  end

  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    pre_logout 'exit'
  end
 

end

