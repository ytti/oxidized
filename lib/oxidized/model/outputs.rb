module Oxidized
  module Models
    # The `Model` class represents a network device or system in Oxidized.
    # It defines methods for interacting with the device and managing outputs related to its configuration.
    # This class contains the `Outputs` class, which manages the collection and manipulation of configuration outputs.
    #
    # This class also utilizes `Refinements`, allowing for special behavior when working with certain methods.
    class Model
      using Refinements

      # The `Outputs` class manages configuration outputs for the `Oxidized::Models::Model`.
      # It provides methods to add, retrieve, and manipulate outputs, and to convert
      # them to a configuration string. Outputs can be stored, filtered by type, and
      # concatenated into a single configuration output.
      class Outputs
        # Converts all outputs to a single configuration string.
        #
        # @return [String] A concatenated string of all outputs.
        def to_cfg
          type_to_str(nil)
        end

        # Converts outputs of a specified type to a single string.
        #
        # @param want_type [String, nil] The type of outputs to convert to a string.
        #   If `nil`, converts all outputs.
        # @return [String] A concatenated string of outputs of the specified type.
        def type_to_str(want_type)
          type(want_type).map { |out| out }.join
        end

        # Adds a new output to the end of the list.
        #
        # @param output [Object] The output object to add.
        def <<(output)
          @outputs << output
        end

        # Adds a new output to the beginning of the list.
        #
        # @param output [Object] The output object to unshift (prepend).
        def unshift(output)
          @outputs.unshift output
        end

        # Retrieves all outputs.
        #
        # @return [Array<Object>] An array containing all output objects.
        def all
          @outputs
        end

        # Retrieves outputs of a specified type.
        #
        # @param type [String] The type of outputs to retrieve.
        # @return [Array<Object>] An array of outputs matching the specified type.
        def type(type)
          @outputs.select { |out| out.type == type }
        end

        # Retrieves all unique, non-nil output types.
        #
        # @return [Array<String>] An array of unique output types.
        def types
          @outputs.map { |out| out.type }.uniq.compact
        end

        private

        # Initializes the Outputs object.
        # Sets up an empty array to hold the outputs.
        #
        # @return [void]
        def initialize
          @outputs = []
        end
      end
    end
  end
end
