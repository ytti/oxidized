module Oxidized::Config::Vars
  # convenience method for accessing node, group or global level user variables
  # nil values will be ignored
  def vars name
    r = @node.vars[name] unless @node.vars.nil?
    if Oxidized::CFG.groups.has_key?(@node.group)
      if Oxidized::CFG.groups[@node.group].vars.has_key?(name.to_s)
        r ||= Oxidized::CFG.groups[@node.group].vars[name.to_s]
      end
    end
    r ||= Oxidized::CFG.vars[name.to_s] if Oxidized::CFG.vars.has_key?(name.to_s)
    r
  end
end

