module Oxidized::Config::Vars
  # convenience method for accessing node, group or global level user variables
  # nil values will be ignored
  def vars(name)
    r = @node.vars[name.to_s] unless @node.vars.nil?
    if Oxidized.config.groups.has_key?(@node.group)
      r ||= Oxidized.config.groups[@node.group].vars[name.to_s] if Oxidized.config.groups[@node.group].vars.has_key?(name.to_s)
    end
    if Oxidized.config.models.has_key?(@node.model.class.name.to_s.downcase)
      r ||= Oxidized.config.models[@node.model.class.name.to_s.downcase].vars[name.to_s] if Oxidized.config.models[@node.model.class.name.to_s.downcase].vars.has_key?(name.to_s)
    end
    r ||= Oxidized.config.vars[name.to_s] if Oxidized.config.vars.has_key?(name.to_s)
    r
  end
end
