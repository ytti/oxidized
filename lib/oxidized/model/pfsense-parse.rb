require_relative '../parsed'

module PfSenseParse
  def parse outputs
    cfg = outputs.to_cfg
    info = Oxidized::Parsed.new

    cfg.match(/<pfsense>\s*<version>([0-9.]+)<\/version>/) do
      info.firmware_version = Regexp.last_match(1)
    end

    info
  end
end