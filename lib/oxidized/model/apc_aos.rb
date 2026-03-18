class Apc_aos < Oxidized::Model # rubocop:disable Naming/ClassAndModuleCamelCase
  using Refinements

  comment '; '

  cmd 'config.ini' do |cfg|
    logger.warn "Apc_aos is deprecated, use ApcAos instead."

    cfg.gsub!(/^; Configuration file, generated on.*\n/, '')
    cfg
  end

  cfg :ftp, :scp do
  end
end
