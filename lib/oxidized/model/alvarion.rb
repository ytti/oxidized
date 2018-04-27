class Alvarion < Oxidized::Model
  # Used in Alvarion wisp equipment

  # Run this command as an instance of Model so we can access node
  pre do
    cmd "#{node.auth[:password]}.cfg"
  end

  cfg :tftp do
  end
end
