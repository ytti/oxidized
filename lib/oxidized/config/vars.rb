module Oxidized::Config::Vars
  # convenience method for accessing node, group or global level user variables
  def vars(name)
    if @node.vars&.has_key?(name)
      @node.vars[name]
    elsif Oxidized.config.groups.has_key?(@node.group) && Oxidized.config.groups[@node.group].vars.has_key?(name.to_s)
      Oxidized.config.groups[@node.group].vars[name.to_s]
    elsif Oxidized.config.models.has_key(@node.model.class.name.to_s.downcase) && Oxidized.config.models[@node.model.class.name.to_s.downcase].vars.has_key?(name.to_s)
      Oxidized.config.models[@node.model.class.name.to_s.downcase].vars[name.to_s]
    elsif Oxidized.config.vars.has_key?(name.to_s)
      Oxidized.config.vars[name.to_s]
    end
  end
end
