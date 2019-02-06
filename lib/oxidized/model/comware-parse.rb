module ComwareParse
    def parse outputs
      cfg = outputs.to_cfg
      info = Oxidized::Parsed.new
  
      cfg.match(/# (3Com Corporation)/) do
      info.manufacturer = Regexp.last_match(1)
      end
  
      cfg.match(/# (Switch .+?) Software Version 3Com OS (V[0-9.a-z]+)/) do
      info.name = Regexp.last_match(1)
      info.firmware_version = Regexp.last_match(2)
      end
  
      cfg.match(/Switch .+? 48-Port with ([0-9]+) Processor/) do
      info.cores = Regexp.last_match(1).to_i
      end
  
      cfg.match(/# ([0-9]+)M   bytes DRAM/) do
      info.ram = Regexp.last_match(1).to_i * 1024 * 1024
      end
  
      cfg.match(/# ([0-9]+)M   bytes Flash Memory/) do
      info.nvmem = Regexp.last_match(1).to_i * 1024 * 1024
      end
  
      info
    end
  end
  