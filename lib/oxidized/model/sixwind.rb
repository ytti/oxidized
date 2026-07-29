class SixWind < Oxidized::Model
  using Refinements

  prompt /^[\w\s().@_\/:-]+> $/
  comment '# '

  cmd :all do |cfg|
    cfg.cut_both
  end

  cmd :secret do |cfg|
    cfg.gsub!(/\b((?:password|secret)(?: \d)? )\S+/, '\\1<secret hidden>')
    cfg
  end

  cmd 'show product version' do |cfg|
    comment cfg
  end

  # Storage vars:
  # - sixwind_default_storage_type: "hierarchical" (default) or "fullpath".
  # - sixwind_store_alternative: true (default) stores the other format as
  #   "sixwind-fullpath" or "sixwind-hierarchical"; false stores only the default.
  def sixwind_storage_config
    default_type = vars(:sixwind_default_storage_type) || 'hierarchical'
    unless %w[hierarchical fullpath].include?(default_type)
      raise Oxidized::InvalidConfig,
            'sixwind_default_storage_type must be "hierarchical" or "fullpath"'
    end

    store_alternative = vars(:sixwind_store_alternative)
    store_alternative = true if store_alternative.nil?

    unless [true, false].include?(store_alternative)
      raise Oxidized::InvalidConfig,
            'sixwind_store_alternative must be true or false'
    end

    { default_type: default_type, store_alternative: store_alternative }
  end

  def sixwind_store_hierarchical?
    config = sixwind_storage_config
    config[:default_type] == 'hierarchical' || config[:store_alternative]
  end

  def sixwind_store_fullpath?
    config = sixwind_storage_config
    config[:default_type] == 'fullpath' || config[:store_alternative]
  end

  cmd 'show config nodefault', if: -> { sixwind_store_hierarchical? } do |cfg|
    if sixwind_storage_config[:default_type] == 'fullpath'
      cfg.type = 'sixwind-hierarchical'
      cfg.name = 'hierarchical'
    end
    cfg
  end

  cmd 'show config nodefault fullpath', if: -> { sixwind_store_fullpath? } do |cfg|
    if sixwind_storage_config[:default_type] == 'hierarchical'
      cfg.type = 'sixwind-fullpath'
      cfg.name = 'fullpath'
    end
    cfg
  end

  cfg :ssh do
    post_login 'cliconfig pager enabled false'
    pre_logout 'exit'
  end
end
