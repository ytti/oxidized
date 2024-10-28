module Oxidized
  module Models
    # Represents the FortiWLC model.
    #
    # Handles configuration retrieval and processing for FortiWLC devices.

    class FortiWLC < Oxidized::Models::Model
      using Refinements

      comment '# '

      cmd :all do |cfg, cmdstring|
        new_cfg = comment "COMMAND: #{cmdstring}\n"
        new_cfg << cfg.each_line.to_a[1..-2].map { |line| line.gsub(/(conf_file_ver=)(.*)/, '\1<stripped>\3') }.join
      end

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^([-\w.\/:?\[\]()]+[#>]\s?)$/

      cmd 'show controller' do |cfg|
        comment cfg
      end
      cmd 'show ap' do |cfg|
        comment cfg
      end
      cmd 'show running-config' do |cfg|
        comment cfg
      end

      cfg :telnet, :ssh do
        pre_logout "exit\n"
      end
    end
  end
end
