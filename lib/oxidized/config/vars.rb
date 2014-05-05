module Oxidized::Config::Vars
  # convenience method for accessing node, group or global level user variables
  # nil values will be ignored
  def vars name
    r =   @node.vars[name]
    r ||= CFG.groups[@node.group].vars[name.to_s] if CFG.groups.has_key?(@node.group)
    r ||= CFG.vars[name.to_s]
  end
end

