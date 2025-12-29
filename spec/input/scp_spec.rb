require_relative '../spec_helper'
require 'oxidized/input/scp'

describe Oxidized::SCP do
  describe ".rescue_fail" do
    it "returns RESCUE_FAIL from Oxidized::Input" do
      result = Oxidized::SCP.rescue_fail

      _(result[Errno::ECONNREFUSED]).must_equal :debug
      _(result[Oxidized::PromptUndetect]).must_equal :warn
      _(result[Errno::EHOSTUNREACH]).must_equal :warn
      _(result[Errno::ENETUNREACH]).must_equal :warn
      _(result[Timeout::Error]).must_equal :warn
    end
    it "returns its own RESCUE_FAIL" do
      result = Oxidized::SCP.rescue_fail

      # Check that SSH-specific exceptions are included
      _(result[Net::SSH::Disconnect]).must_equal :debug
      _(result[Net::SSH::ConnectionTimeout]).must_equal :debug
      _(result[Net::SCP::Error]).must_equal :warn
      _(result[Net::SSH::HostKeyUnknown]).must_equal :warn
      _(result[Net::SSH::AuthenticationFailed]).must_equal :warn
    end
  end
end
