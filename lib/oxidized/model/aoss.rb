class Aoss < Oxidized::Model
  using Refinements

  # HPE Aruba Networking Switch Operating System
  # Tested on Aruba JL354A 2540-24G-4SFP+ Switch with Software revision YC.16.11.0008

  prompt /(^\r|\e\[24;[0-9][hH])?([\w\s.-]+[#>] )/

  comment '! '

  # replace next line control sequence with a new line
  expect /(\e\[1M\e\[\??\d+(;\d+)*[A-Za-z]\e\[1L)|(\eE)/ do |data, re|
    data.gsub re, "\n"
  end

  # replace all used vt100 control sequences
  expect /\e\[\??\d+(;\d+)*[A-Za-z]/ do |data, re|
    data.gsub re, ''
  end

  # handle "press any key" before prompt shows
  expect /^Press any key to continue$/ do
    send ' '
    ""
  end

  # Handle logout
  expect /^Do you want to log out.*$/ do |data, re|
    send 'y'
    data.gsub re, ''
  end

  cmd 'show running-config'

  cfg :ssh do
    pre_logout 'logout'
    post_login 'no page'
  end
end
