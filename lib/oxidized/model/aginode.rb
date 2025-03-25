class Aginode < Oxidized::Model
  using Refinements
••
  prompt /^([\w.@-]+[#>]\s?)$/

  cmd 'show running-config all no-pause'
  cfg :telnet do
    username /^Name:/
    password /^\r?Password:/
  end
••
  cfg :telnet do
    pre_logout 'exit'
  end
end
