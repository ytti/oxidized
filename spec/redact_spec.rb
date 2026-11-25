require_relative 'spec_helper'
require 'oxidized/redact'

describe Oxidized::Redact do
  describe '.sensitive?' do
    %w[password passphrase secret token community credential
       private_key api_key access_key enable Authorization].each do |word|
      it "matches #{word}" do
        _(Oxidized::Redact.sensitive?(word)).must_equal true
      end
    end

    %w[hostname interval output model].each do |word|
      it "does not match #{word}" do
        _(Oxidized::Redact.sensitive?(word)).must_equal false
      end
    end

    it "accepts symbols" do
      _(Oxidized::Redact.sensitive?(:password)).must_equal true
    end
  end

  describe '.value' do
    it "hides the value of a sensitive name" do
      _(Oxidized::Redact.value(:password, "secret")).must_equal '[REDACTED]'
    end

    it "returns the value of a non-sensitive name" do
      _(Oxidized::Redact.value(:model, "ios")).must_equal "ios"
    end
  end
end
