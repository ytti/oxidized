class FRR < Oxidized::Model
  prompt /^((\w*)@(.*)):/
  comment '# '

  # add a comment in the final conf
  def add_comment(comment)
    "\n###### #{comment} ######\n"
  end

  cmd :all do |cfg|
    cfg.cut_both
  end

  # show the persistent configuration
  pre do
    cfg = add_comment 'FRR CONFIG'
    cfg += cmd 'sudo vtysh -c "show running-config"'
  end

  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    post_login do
      if vars(:enable) == true
        cmd "sudo -i"
        cmd @node.auth[:password]
      elsif vars(:enable)
        cmd "sudo -i", /^Password:/
        cmd vars(:enable)
      end
    end

    pre_logout do
      cmd "exit" if vars(:enable)
    end
    pre_logout 'exit'
    pre_logout 'exit'
  end
end
