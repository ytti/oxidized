module Oxidized
  module Models
    # # JunOS Configuration
    #
    # Create login class cfg-view
    #
    # ```text
    # set system login class cfg-view permissions view-configuration
    # set system login class cfg-view allow-commands "(show)|(set cli screen-length)|(set cli screen-width)"
    # set system login class cfg-view deny-commands "(clear)|(file)|(file show)|(help)|(load)|(monitor)|(op)|(request)|(save)|(set)|(start)|(test)"
    # set system login class cfg-view deny-configuration all
    # ```
    #
    # Create a user with cfg-view class
    #
    # ```text
    # set system login user oxidized class cfg-view
    # set system login user oxidized authentication plain-text-password "verysecret"
    # ```
    #
    # The commands Oxidized executes are:
    #
    # 1. set cli screen-length 0
    # 2. set cli screen-width 0
    # 3. show version
    # 4. show chassis hardware
    # 5. show system license
    # 6. show system license keys
    # 7. show virtual-chassis (ex22|ex33|ex4|ex8|qfx only)
    # 8. show chassis fabric reachability (MX960 only)
    # 9. show configuration
    #
    # Oxidized can now retrieve your configuration!
    #
    # Back to [Model-Notes](README.md)

    class JunOS < Oxidized::Models::Model
      using Refinements
      comment '# '

      def telnet
        @input.class.to_s.match(/Telnet/)
      end

      cmd :all do |cfg|
        cfg = cfg.cut_both if screenscrape
        cfg.gsub!(/  scale-subscriber (\s+)(\d+)/, '  scale-subscriber                <count>')
        cfg.gsub!(/VMX-BANDWIDTH\s+(\d+) (.*)/, 'VMX-BANDWIDTH                  <count> \2')
        cfg.lines.map { |line| line.rstrip }.join("\n") + "\n"
      end

      cmd :secret do |cfg|
        cfg.gsub!(/community (\S+) {/, 'community <hidden> {')
        cfg.gsub!(/(ssh-(rsa|dsa|ecdsa|ecdsa-sk|ed25519|ed25519-sk) )".*; ## SECRET-DATA/, '<secret removed>')
        cfg.gsub!(/ "\$\d\$\S+; ## SECRET-DATA/, ' <secret removed>;')
        cfg
      end

      cmd 'show version' do |cfg|
        @model = Regexp.last_match(1) if cfg =~ /^Model: (\S+)/
        comment cfg
      end

      post do
        out = ''
        case @model
        when 'mx960'
          out << cmd('show chassis fabric reachability') { |cfg| comment cfg }
        when /^(ex22|ex3[34]|ex4|ex8|qfx)/
          out << cmd('show virtual-chassis') { |cfg| comment cfg }
        end
        out
      end

      cmd('show chassis hardware') { |cfg| comment cfg }
      cmd('show system license') do |cfg|
        cfg.gsub!(/  fib-scale\s+(\d+)/, '  fib-scale                       <count>')
        cfg.gsub!(/  rib-scale\s+(\d+)/, '  rib-scale                       <count>')
        comment cfg
      end
      cmd('show system license keys') { |cfg| comment cfg }

      cmd 'show configuration | display omit'

      cfg :telnet do
        username(/^login:/)
        password(/^Password:/)
      end

      cfg :ssh do
        exec true # don't run shell, run each command in exec channel
      end

      cfg :telnet, :ssh do
        post_login 'set cli screen-length 0'
        post_login 'set cli screen-width 0'
        pre_logout 'exit'
      end
    end
  end
end
