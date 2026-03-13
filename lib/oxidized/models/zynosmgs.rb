class ZyNOSMGS < Oxidized::Model
  using Refinements

  PROMPT = /^(\w.*)>(.*)?$/
  # Used in Zyxel MGS Series switches

  prompt PROMPT
  comment '! '

  cmd 'show version' do |cfg|
    clear_output cfg
  end

  cmd 'show running-config' do |cfg|
    clear_output cfg
  end

  cfg :telnet do
    username /^User\s?name(\(1-32 chars\))?:/i
    password /^Password(\(1-32 chars\))?:/i
  end

  cfg :telnet, :ssh do
    pre_logout 'exit'
  end

  private

  def clear_output(output)
    output.gsub PROMPT, ''
  end
end
