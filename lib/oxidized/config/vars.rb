# Oxidized::Config::Vars
#
# This module contains configuration variables used within the Oxidized application.
# It provides methods for managing and accessing these variables, ensuring that
# the configuration is properly loaded and utilized across the application.
module Oxidized::Config::Vars
  # Convenience method for accessing user variables at the node, group, or global level.
  #
  # This method attempts to retrieve a variable by checking various levels of configuration,
  # starting with the node-specific variables, followed by group-level variables, and then
  # falling back to global configuration variables if none are found.
  #
  # The priority of the search is as follows:
  # 1. Node-level variables
  # 2. Group-level variables (model-specific, then general)
  # 3. Global model-level variables
  # 4. Global variables
  #
  # @param name [Symbol, String] the name of the variable to retrieve.
  # @return [Object, nil] the value of the variable, or `nil` if it doesn't exist.
  def vars(name)
    model_name = @node.model.class.name.to_s.downcase

    # Check if the node has the variable defined
    if @node.vars&.has_key?(name)
      @node.vars[name]

    # Check if the group has model-specific variables defined
    elsif Oxidized.config.groups.has_key?(@node.group) && Oxidized.config.groups[@node.group].models.has_key(model_name) && Oxidized.config.groups[@node.group].models[model_name].vars.has_key?(name.to_s)
      Oxidized.config.groups[@node.group].models[model_name].vars[name.to_s]

    # Check if the group has general variables defined
    elsif Oxidized.config.groups.has_key?(@node.group) && Oxidized.config.groups[@node.group].vars.has_key?(name.to_s)
      Oxidized.config.groups[@node.group].vars[name.to_s]

    # Check if the global model has variables defined
    elsif Oxidized.config.models.has_key(model_name) && Oxidized.config.models[model_name].vars.has_key?(name.to_s)
      Oxidized.config.models[model_name].vars[name.to_s]

    # Check if there are global variables defined
    elsif Oxidized.config.vars.has_key?(name.to_s)
      Oxidized.config.vars[name.to_s]
    end
  end
end
