# PanOS API-based model for Oxidized
#
# The API-based model produced an XML configuration file that can actually be
# restored as a configuration backup. Make sure to use the "http" input for
# this module.

begin
  # Nokogiri is required because the PanOS API, as well as the
  # configuration file format uses XML. It is required to parse API
  # responses, as well as to pretty-print the configuration XML file
  # when saving it.
  require 'nokogiri'
rescue LoadError
  # Oxidized itself depends on mechanize, which in turn depends on
  # nokogiri, so this should never happen.
  raise Oxidized::OxidizedError, 'nokogiri not found: sudo gem install nokogiri'
end

class PanOS_API < Oxidized::Model # rubocop:disable Naming/ClassAndModuleCamelCase
  using Refinements

  # Callback function for getting the configuration file.
  cfg_cb = lambda do
    url_param = URI.encode_www_form(
      user:     @node.auth[:username],
      password: @node.auth[:password],
      type:     'keygen'
    )

    kg_r = get_http "/api?#{url_param}"

    # Parse the XML API response for the keygen request.
    kg_x = Nokogiri::XML(kg_r)

    # Check if keygen was successful. If not we'll throw an error.
    status = kg_x.xpath('//response/@status').first
    if status.to_s != 'success'
      msg = kg_x.xpath('//response/result/msg').text
      raise Oxidized::OxidizedError, "Could not generate PanOS API key: #{msg}"
    end

    # If we reach here, keygen was successful, so get the API key
    # out of the keygen XML response.
    apikey = kg_x.xpath('//response/result/key').text.to_s

    # Now that we have the API key, we can request a configuration
    # export.
    url_param = URI.encode_www_form(
      key:      apikey,
      category: 'configuration',
      type:     'export'
    )

    cfg = get_http "/api?#{url_param}"

    # The configuration export is in XML format. Unfortunately,
    # it's just one long line of XML that's not especially human
    # readable or diffable.
    #
    # Thus, we will load the XML document and then emit it again
    # with indentation set up, so that it's still a valid
    # configuration, and also possible to read.
    Nokogiri::XML(cfg).to_xml(indent: 2)
  end

  # Define the command based on the callback above.
  cmd cfg_cb

  cfg :http do
    # Palo Alto's API always requires HTTPS as far as I know.
    @secure = true
  end
end
