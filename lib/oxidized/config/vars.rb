module Oxidized
  class Config
    module Vars
      # convenience method for accessing node, group or global level user variables
      def vars(name)
        model_name = @node.model.class.name.to_s.downcase
        groups = Oxidized.config.groups
        models = Oxidized.config.models
        group = groups[@node.group] if groups.has_key?(@node.group)
        model = models[model_name] if models.has_key?(model_name)
        group_model = group.models[model_name] if group&.models&.has_key?(model_name)

        scopes = {
          node:        @node.vars,
          group_model: group_model&.vars,
          group:       group&.vars,
          model:       model&.vars,
          vars:        Oxidized.config.vars
        }

        scopes.each do |scope_name, scope|
          next unless scope&.has_key?(name.to_s)

          val = scope[name.to_s]
          if val.nil?
            Oxidized.logger.debug "vars.rb: scope #{scope_name} has key #{name} with value nil, ignoring scope"
          else
            Oxidized.logger.debug "vars.rb: scope #{scope_name} has key #{name} with value #{val}, using scope"
            return val
          end
        end
        nil
      end
    end
  end
end
