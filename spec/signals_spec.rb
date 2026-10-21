require_relative 'spec_helper'
require 'open3'
require 'rbconfig'

describe Oxidized::Signals do
  # Load order matters: run in a fresh interpreter so Oxidized is loaded
  # before Puma, as it happens when oxidized-web is required by Oxidized.
  def run_ruby(code)
    lib = File.expand_path('../lib', __dir__)
    Open3.capture2e(RbConfig.ruby, '-I', lib, '-e', code)
  end

  describe 'load path compatibility with Puma' do
    it 'does not define Puma::Signal and keeps ::Signal resolvable in Puma' do
      out, status = run_ruby(<<~RUBY)
        require 'oxidized'
        require 'puma'
        require 'puma/detect'
        abort 'Puma::Signal is defined' if Puma.const_defined?(:Signal, false)
        abort 'Signal.list unavailable in Puma' unless Puma.module_eval { Signal.list.key?('HUP') }
        puts 'ok'
      RUBY

      _(status.success?).must_equal true, out
      _(out.strip).must_equal 'ok'
    end

    it 'does not require Puma to be loaded' do
      out, status = run_ruby(<<~RUBY)
        require 'oxidized'
        abort 'Puma was loaded' if defined?(Puma)
        puts 'ok'
      RUBY

      _(status.success?).must_equal true, out
    end
  end

  describe 'SemanticLogger signal handlers' do
    it 'still react to SIGUSR2 and SIGTTIN when Puma is loaded' do
      out, status = run_ruby(<<~RUBY)
        require 'oxidized'
        require 'puma'
        SemanticLogger.add_appender(io: $stdout)
        SemanticLogger.add_signal_handler
        Process.kill('USR2', Process.pid)
        Process.kill('TTIN', Process.pid)
        sleep 0.2
        SemanticLogger.flush
      RUBY

      _(status.success?).must_equal true, out
      _(out).must_match(/Changed global default log level/)
      _(out).must_match(/Thread Dump/)
    end
  end

  describe '.register_signal' do
    it 'runs all handlers registered for a signal' do
      out, status = run_ruby(<<~RUBY)
        require 'oxidized'
        calls = []
        Oxidized::Signals.register_signal('HUP', proc { calls << :first })
        Oxidized::Signals.register_signal('SIGHUP', proc { calls << :second })
        Process.kill('HUP', Process.pid)
        sleep 0.1
        abort "unexpected calls: \#{calls}" unless calls == %i[first second]
        puts 'ok'
      RUBY

      _(status.success?).must_equal true, out
      _(out.strip).must_equal 'ok'
    end
  end
end
