class Enterprise_SONiC < Oxidized::Model # rubocop:disable Naming/ClassAndModuleCamelCase
  using Refinements

  # Remove ANSI escape codes
  expect /\e\[[0-?]*[ -\/]*[@-~]\r?/ do |data, re|
    data.gsub re, ''
  end

  # Matches both sonic-cli and linux terminal
  prompt /^(?:[\w.-]+@[\w.-]+:[~\w\/-]+\$|[\w.-]+#)\s*/
  comment "# "

  def add_comment(comment)
    "\n##### #{comment} #####\n"
  end

  post do
    cmd 'show running-configuration' do |cfg|
      add_comment('CONFIGURATION') + cfg
    end
  end

  cmd 'show version' do |cfg|
    cfg = cfg.each_line.reject { |line| line.match /Uptime/ }.join
    add_comment('VERSION') + cfg
  end

  cmd 'show platform syseeprom' do |cfg|
    add_comment('SYSEEPROM') + cfg
  end

  cmd :all do |cfg|
    cfg.cut_both
  end

  cfg :ssh do
    # if user logs in to linux == has admin rights
    if vars(:admin) == true
      post_login do
        cmd "sonic-cli\n"
      end
    end
    post_login 'terminal length 0'
    pre_logout 'exit'
  end
end
