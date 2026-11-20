class SRLinux < Oxidized::Model
  using Refinements

  comment "# "

  prompt /[ABCD]:\S+#\s*/

  cmd :all do |cfg|
    if screenscrape
      cfg = cfg.cut_both
      cfg.gsub! /--{(?:\s\[[\w\s]+\]){0,5}[+*\s]{1,}running\s}--\[.+?\]--/, ""
    end
    cfg
  end

  cmd :secret do |cfg|
    cfg.gsub! /password (\S+)/, "password <hidden>"
    cfg
  end

  cmd "info flat", if: -> { vars(:srlinux_config_format).nil? || %w[flat both].include?(vars(:srlinux_config_format)) }

  cmd "info | as json", if: -> { %w[json both].include?(vars(:srlinux_config_format)) } do |cfg|
    if vars(:srlinux_config_format) == "both"
      cfg.type = "srlinux-json"
      cfg.name = "json"
    end
    cfg
  end

  cmd "show version" do |cfg|
    cfg = cfg.reject_lines [/^Free Memory\s*:/]
    comment cfg
  end

  cmd "show platform chassis" do |cfg|
    comment cfg
  end

  cfg :ssh do
    exec true
    post_login "environment cli-engine type basic"
    pre_logout "quit"
  end
end
