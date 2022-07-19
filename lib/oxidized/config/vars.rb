module Oxidized::Config::Vars
  # convenience method for accessing node, group or global level user variables
  def vars(name)
    model_name = @node.model.class.name.to_s.downcase
    if @node.vars&.has_key?(name)
      @node.vars[name]
    elsif Oxidized.config.groups.has_key?(@node.group) && Oxidized.config.groups[@node.group].models.has_key(model_name) && Oxidized.config.groups[@node.group].models[model_name].vars.has_key?(name.to_s)
      Oxidized.config.groups[@node.group].models[model_name].vars[name.to_s]
    elsif Oxidized.config.groups.has_key?(@node.group) && Oxidized.config.groups[@node.group].vars.has_key?(name.to_s)
      Oxidized.config.groups[@node.group].vars[name.to_s]
    elsif Oxidized.config.models.has_key(model_name) && Oxidized.config.models[model_name].vars.has_key?(name.to_s)
      Oxidized.config.models[model_name].vars[name.to_s]
    elsif Oxidized.config.vars.has_key?(name.to_s)
      Oxidized.config.vars[name.to_s]
    end
  end
end
