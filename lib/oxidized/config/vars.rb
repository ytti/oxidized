module Oxidized::Config::Vars
  # convenience method for accessing node, group or global level user variables
  # nil values will be ignored
  def vars name
    r =   @node.vars[name] unless @node.vars.nil?
    r ||= Oxidized::CFG.groups[@node.group].vars[name.to_s] if Oxidized::CFG.groups.has_key?(@node.group)
    r ||= Oxidized::CFG.vars[name.to_s] if Oxidized::CFG.vars.has_key?(name)
    r
  end
end
