module Oxidized
  module Models
    # Represents the NetScaler model.
    #
    # Handles configuration retrieval and processing for NetScaler devices.

    class NetScaler < Oxidized::Models::Model
      using Refinements

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^(.*[\w\.-]*>\s?)$/
      comment '# '

      cmd :all do |cfg|
        cfg.each_line.to_a[1..-3].join
      end

      cmd 'show version' do |cfg|
        comment cfg
      end

      cmd 'show hardware' do |cfg|
        comment cfg
      end

      cmd 'show partition' do |cfg|
        comment cfg
      end

      cmd :secret do |cfg|
        cfg.gsub! /\w+\s(-encrypted)/, '<secret hidden> \\1'
        cfg
      end

      # @!visibility private
      # check for multiple partitions
      cmd 'show partition' do |cfg|
        @is_multiple_partition = cfg.include? 'Name:'
      end

      post do
        if @is_multiple_partition
          multiple_partition
        else
          single_partition
        end
      end

      # Single partition mode.
      #
      # Executes the 'show ns ns.conf' command on the device.
      #
      # @return [String] The configuration output.
      def single_partition
        # @!visibility private
        # Single partition mode
        cmd 'show ns ns.conf' do |cfg|
          cfg
        end
      end

      # Multiple partition mode.
      #
      # Executes the 'show partition' command and retrieves configurations for all partitions.
      #
      # @return [String] The combined configuration output from all partitions.
      def multiple_partition
        # @!visibility private
        # Multiple partition mode
        cmd 'show partition' do |cfg|
          allcfg = ""
          partitions = [["default"]] + cfg.scan(/Name: (\S+)$/)
          partitions.each do |part|
            allcfg = allcfg + "\n\n####################### [ partition " + part.join(" ") + " ] #######################\n\n"
            cmd "switch ns partition " + part.join(" ") + "; show ns ns.conf; switch ns partition default" do |cfgpartition|
              allcfg += cfgpartition
            end
          end
          allcfg
        end
      end

      cfg :ssh do
        pre_logout 'exit'
      end
    end
  end
end
