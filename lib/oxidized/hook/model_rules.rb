def source_node_transform(ctx)
  rules = cfg["rules"] || []
  node = ctx.node

  matched_model = nil
  rules.each_with_index do |rule, idx|
    match = true
    rule.each do |key, value|
      # Пропускаем ключи, которые не участвуют в сравнении
      next if key == 'model' || key == 'description'
      node_value = node[key.to_sym] || node[key.to_s]
      if node_value.to_s.strip.downcase != value.to_s.strip.downcase
        match = false
        break
      end
    end
    if match
      matched_model = rule['model']
      desc = rule['description'] ? " (#{rule['description']})" : ""
      logger.debug "ModelRulesHook: rule #{idx+1}#{desc} matched -> #{matched_model}"
      break
    end
  end

  if matched_model
    old_model = node[:model] || node['model']
    node = node.merge(model: matched_model)
    logger.debug "ModelRulesHook: changed model from #{old_model.inspect} to #{matched_model.inspect}"
  else
    logger.debug "ModelRulesHook: no rule matched, keeping existing model: #{node[:model] || node['model'].inspect}"
  end
  node
end
