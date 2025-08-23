require_relative '../spec_helper'
require 'oxidized/input/http'

describe Oxidized::HTTP do
  def get_node(ip = "127.0.0.1")
    Oxidized::Node.new(ip:       ip,
                       name:     'example.com',
                       input:    'http',
                       output:   'git',
                       model:    'junos',
                       username: 'user',
                       password: 'pass')
  end

  def get_uri(ip, path, secure: false)
    @http = Oxidized::HTTP.new
    @http.connect(get_node(ip))
    @http.instance_variable_set("@secure", secure)
    @http.send("get_uri", path)
  end

  before(:each) do
    Oxidized.asetus = Asetus.new
  end

  describe "#connect" do
    it "it should return valid insecure IPv6 URI for a path with query" do
      uri = get_uri("2001:db8::42", "/path?query")
      _(uri.to_s).must_equal "http://[2001:db8::42]/path?query"
    end
    it "it should return valid secure IPv4 URI for a path with query" do
      uri = get_uri("192.0.0.42", "/this/is/path?and=this&is=query", secure: true) do
        _(uri.to_s).must_equal "https://192.0.0.42/this/is/path?and=this&is=query"
      end
    end
  end
end
