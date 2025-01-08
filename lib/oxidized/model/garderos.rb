class Garderos < Oxidized::Model
  using Refinements
  # Garderos GmbH https://www.garderos.com/
  # Routers for harsh environments
  # grs = Garderos Router Software

  # Remove ANSI escape codes
  expect /\e\[[0-?]*[ -\/]*[@-~]\r?/ do |data, re|
    data.gsub re, ''
  end

  # the prompt does not need to match escape codes, as they have been removed above
  prompt /[\w-]+# /
  comment '# '

  cmd :all do |cfg|
    # Remove the echo of the entered command and the prompt after it
    cfg.cut_both
  end

  cmd 'show system version' do |cfg|
    comment "#{cfg}\n"
  end

  cmd 'show system serial' do |cfg|
    comment "#{cfg}\n"
  end

  # If we have a radio modem installed, we'd like to list the SIM Card
  cmd 'show hardware wwan wwan0 sim' do |cfg|
    if cfg.start_with? 'Unknown command'
      String.new('')
    else
      comment "#{cfg}\n"
    end
  end

  cmd 'show configuration running'

  cfg :ssh do
    pre_logout 'exit'
  end
end
