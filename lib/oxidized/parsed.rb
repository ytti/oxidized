module Oxidized
  class Parsed
    attr_accessor :manufacturer, :name, :firmware_version, :cores, :ram, :nvmem

    def to_h
      {:manufacturer => manufacturer,
       :name => name,
       :firmware_version => firmware_version,
       :cores => cores,
       :ram => ram,
       :nvmem => nvmem
      }
    end
  end
end