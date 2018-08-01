# Huawei SmartAX DSL/GPON/DOCSIS HeadEnd units
class Huawei_SmartAX < Oxidized::Model
    comment '#'

    # Handle paging - if config is greater that 512 lines, it will still paginate it.
    # ---- More ( Press 'Q' to break ) ----
    expect /---- More \( Press 'Q' to break \) ----.*$/ do |data, re|
      send " "
      data.sub re, ''
    end

    cmd :all do |cfg|
      if cfg.respond_to?('cut_both', false)
        cfg.cut_both
      else
        cfg.each_line.to_a[1..-2].join
      end
    end

    # 'display current-configuration' will retrieve the current configuration running in RAM
    # 'display saved-configuration' will retrieve the last configuration saved to local flash - and will be the config used on device reboot
    cmd 'display current-configuration' do |cfg|
        cfg
    end

    cfg :ssh do
      # Turn off 'human' prompting on command entry
      post_login "undo smart"
      post_login "undo interactive"
      post_login "scroll 512"
      post_login "undo idle-timeout"
      # No password is required to escalate into the administrator mode to get the current configuration
      if vars(:enable)
        post_login "enable"
      end
      # Exit from administrator mode
      pre_logout "quit"
    end
end
