require_relative '../spec_helper'
require 'oxidized/input/sshbase'

describe Oxidized::SSHBase do
  before(:each) do
    Oxidized.asetus = Asetus.new
  end

  describe '#config_name' do
    it "returns the configuration name" do
      ssh = Oxidized::SSHBase.new
      _(ssh.config_name).must_equal 'sshbase'
    end
  end

  describe '#must_secure?' do
    it "returns false when nothing is configured" do
      ssh = Oxidized::SSHBase.new
      _(ssh.must_secure?).must_equal false
    end

    it "returns true when secure is configured to false" do
      Oxidized.config.input.sshbase.secure = false

      ssh = Oxidized::SSHBase.new
      _(ssh.must_secure?).must_equal false
    end

    it "returns true when secure is configured to true" do
      Oxidized.config.input.sshbase.secure = true

      ssh = Oxidized::SSHBase.new
      _(ssh.must_secure?).must_equal true
    end
  end
end
