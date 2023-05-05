class ZyNOS < Oxidized::Model
  using Refinements

  # Used in Zyxel DSLAMs, such as SAM1316

  comment '! '

  cmd 'config-0'

  cfg :ftp do
  end
end
