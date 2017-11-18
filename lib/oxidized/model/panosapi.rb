class PanOSAPI < Oxidized::Model
  begin
    require 'nokogiri'
  rescue LoadError
    raise OxidizedError, 'nokogiri not found: sudo gem install nokogiri'
  end

  # Run this command as an instance of Model so we can access node
  pre do
    apikey_req = Net::HTTP::Get.new '/api/?' + URI.encode_www_form({
      :user => node.auth[:username],
      :password => node.auth[:password],
      :type => 'keygen'
    })

    cmd apikey_req do |response|
      doc = Nokogiri::XML(response.body)
      status = doc.xpath('//response/@status').first
      if status.to_s != 'success'
        msg = doc.xpath('//response/result/msg').text
        raise OxidizedError, ('Could not generate PanOS API key: ' + msg)
      end
      apikey = doc.xpath('//response/result/key').text.to_s
    end
  end

  config_export_req = Net::HTTP::Get.new '/api/?' + URI.encode_www_form({
    :key => apikey,
    :type => 'export',
    :category => 'configuration'
  })

  cmd config_export_req do |response|
    Nokogiri::XML(response.body).to_xml(:indent => 2)
  end

  cfg :http do
  end

end
