require_relative '../spec_helper'
require 'oxidized/input/http'

describe Oxidized::HTTP do
  before(:each) do
    Oxidized.asetus = Asetus.new
    Oxidized::Node.any_instance.stubs(:resolve_repo)
    Oxidized::Node.any_instance.stubs(:resolve_input)
    Oxidized::Node.any_instance.stubs(:resolve_output)
  end

  def get_node(ip = "127.0.0.1")
    Oxidized::Node.new(ip:       ip,
                       name:     'example.com',
                       input:    'http',
                       output:   'git',
                       model:    'junos',
                       username: 'user',
                       password: 'pass')
  end

  def build_http(ip = "127.0.0.1", secure: false)
    http = Oxidized::HTTP.new
    http.connect(get_node(ip))
    http.instance_variable_set("@secure", secure)
    http
  end

  def get_uri(ip, path, secure: false)
    build_http(ip, secure: secure).send("get_uri", path)
  end

  describe "#get_uri" do
    it "it should return valid insecure IPv6 URI for a path with query" do
      uri = get_uri("2001:db8::42", "/path?query")
      _(uri.to_s).must_equal "http://[2001:db8::42]/path?query"
    end
    it "it should return valid secure IPv4 URI for a path with query" do
      uri = get_uri("192.0.0.42", "/this/is/path?and=this&is=query", secure: true)
      _(uri.to_s).must_equal "https://192.0.0.42/this/is/path?and=this&is=query"
    end
    it "it should return valid secure IPv6 URI for a path without query" do
      uri = get_uri("2001:db8::42", "/path", secure: true)
      _(uri.to_s).must_equal "https://[2001:db8::42]/path"
    end
  end

  describe "#get_http" do
    it "performs a GET request and returns the response body" do
      http = build_http(secure: true)

      response = mock("Net::HTTPResponse")
      response.stubs(:code).returns("200")
      response.stubs(:[]).returns(nil)
      response.stubs(:body).returns("OK")

      net_http = mock("Net::HTTP")
      net_http.expects(:request).with do |req|
        _(req).must_be_instance_of Net::HTTP::Get
        _(req.path).must_equal "/api/test/path/1"
        true
      end.returns(response)

      Net::HTTP.expects(:start).yields(net_http).returns(response)

      body = http.send(:get_http, "/api/test/path/1")
      _(body).must_equal "OK"
    end
  end

  describe "#post_http" do
    it "performs a POST request with given body and headers and returns the response body" do
      http = build_http(secure: true)

      response = mock("Net::HTTPResponse")
      response.stubs(:code).returns("200")
      response.stubs(:[]).returns(nil)
      response.stubs(:body).returns('{"result":"ok"}')

      net_http = mock("Net::HTTP")
      net_http.expects(:request).with do |req|
        _(req).must_be_instance_of Net::HTTP::Post
        _(req.path).must_equal "/api/test/path/2"
        _(req["Content-Type"]).must_equal "application/json"
        _(req["X-Test"]).must_equal "42"
        _(req.body).must_equal '{"header-name":"Some data"}'
        true
      end.returns(response)

      Net::HTTP.expects(:start).yields(net_http).returns(response)

      body = http.send(:post_http,
                       "/api/test/path/2",
                       '{"header-name":"Some data"}',
                       "Content-Type" => "application/json",
                       "X-Test"       => "42")

      _(body).must_equal '{"result":"ok"}'
    end

    it "does not override Authorization header when it is provided in extra headers" do
      http = build_http

      http.instance_variable_set("@username", "testuser")
      http.instance_variable_set("@password", "pass123")

      response = mock("Net::HTTPResponse")
      response.stubs(:code).returns("403")
      response.stubs(:[]).returns(nil)
      response.stubs(:body).returns("forbidden")

      expected_auth = "Token xyz123"

      net_http = mock("Net::HTTP")
      net_http.expects(:request).with do |req|
        _(req).must_be_instance_of Net::HTTP::Post
        _(req["Authorization"]).must_equal expected_auth
        true
      end.returns(response)

      Net::HTTP.expects(:start).yields(net_http).returns(response)

      http.send(:post_http,
                "/api/test/path/2",
                '{"header-name":"Some data"}',
                "Authorization" => expected_auth)
    end

    it "handles nil body without raising and sends an empty POST body" do
      http = build_http

      response = mock("Net::HTTPResponse")
      response.stubs(:code).returns("200")
      response.stubs(:[]).returns(nil)
      response.stubs(:body).returns("no body")

      net_http = mock("Net::HTTP")
      net_http.expects(:request).with do |req|
        _(req).must_be_instance_of Net::HTTP::Post
        _(req.path).must_equal "/api/test-nil-body"
        true
      end.returns(response)

      Net::HTTP.expects(:start).yields(net_http).returns(response)

      body = http.send(:post_http, "/api/test-nil-body", nil, {})
      _(body).must_equal "no body"
    end
  end
end
