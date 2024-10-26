module Oxidized
  module Models
    # Represents the Aireos model.
    #
    # Handles configuration retrieval and processing for Aireos devices.
    #
    # # Cisco WLC Configuration
    #
    # Create a user with read-write privilege:
    #
    # ```text
    # mgmtuser add oxidized **** read-write
    # ```
    #
    # Oxidized needs read-write privilege in order to execute 'config paging disable'.
    #
    # Back to [Model-Notes](README.md)

    class Aireos < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # AireOS (at least I think that is what it's called, hard to find data)
      # Used in Cisco WLC 5500

      comment '# ' # this complains too, can't find real comment char

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^\([^)]+\)\s>/

      cmd :all do |cfg|
        cfg.cut_both
      end

      # @!visibility private
      # show sysinfo?
      # show switchconfig?

      cmd 'show udi' do |cfg|
        cfg = comment clean cfg
        cfg << "\n"
      end

      cmd 'show boot' do |cfg|
        cfg = comment clean cfg
        cfg << "\n"
      end

      cmd 'show run-config commands' do |cfg|
        clean cfg
      end

      cfg :telnet, :ssh do
        username /^User:\s*/
        password /^Password:\s*/
        post_login 'config paging disable'
      end

      cfg :telnet, :ssh do
        pre_logout do
          send "logout\n"
          send "n"
        end
      end

      # Cleans the configuration by removing unnecessary lines.
      #
      # This method processes the raw configuration data by:
      # - Removing empty lines.
      # - Removing lines matching specific rogue patterns.
      # - Stripping leading carriage returns and whitespace.
      #
      # @param cfg [String] The raw configuration data.
      # @return [String] The cleaned configuration data.
      def clean(cfg)
        out = []
        cfg.each_line do |line|
          next if line =~ /^\s*$/
          next if line =~ /rogue (adhoc|client) (alert|Unknown) [\da-f]{2}:/

          line = line[1..-1] if line[0] == "\r"
          out << line.strip
        end
        out = out.join "\n"
        out << "\n"
      end
    end
  end
end
