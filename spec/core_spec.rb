require_relative 'spec_helper'
require 'oxidized/core'
require 'oxidized/web'

describe Oxidized::Core do
  before do
    Oxidized.asetus = Asetus.new

    Oxidized::Manager.expects(:new)
    Oxidized.stubs(:mgr=)

    Oxidized::HookManager.expects(:from_config)
    Oxidized.stubs(:hooks=)

    @mock_nodes = mock('Oxidized::Nodes')
    @mock_nodes.expects(:empty?).returns(false)
    Oxidized::Nodes.expects(:new).returns(@mock_nodes)

    @mock_worker = mock('Oxidized::Worker')
    Oxidized::Worker.expects(:new).returns(@mock_worker)
    Oxidized::Signals.expects(:register_signal)
  end

  describe '#initialize' do
    it 'runs when extensions not configured' do
      Oxidized::Core.any_instance.expects(:run)

      Oxidized::Core.new(nil)
    end

    it 'runs when only extensions configured' do
      Oxidized.config.extensions = nil
      Oxidized::Core.any_instance.expects(:run)

      Oxidized::Core.new(nil)
    end
    it 'runs when only extensions.oxidized-web configured' do
      Oxidized.config.extensions = Asetus::ConfigStruct.new(
        {
          "oxidized-web" => nil
        }
      )
      Oxidized::Core.any_instance.expects(:run)
      Oxidized::Core.any_instance.expects(:require).with('oxidized/web').never

      Oxidized::Core.new(nil)
    end
    it 'wont run oxidized-web when load = false' do
      Oxidized.config.extensions = Asetus::ConfigStruct.new(
        {
          "oxidized-web" => { "load" => false }
        }
      )
      Oxidized::Core.any_instance.expects(:run)
      Oxidized::Core.any_instance.expects(:require).with('oxidized/web').never

      Oxidized::Core.new(nil)
    end
    it 'runs oxidized-web when load = true' do
      Oxidized.config.extensions = Asetus::ConfigStruct.new(
        {
          "oxidized-web" => { "load" => true }
        }
      )
      Oxidized::Core.any_instance.expects(:require).with('oxidized/web')
      mock_web = mock('Oxidized::API::Web')
      mock_web.expects(:run)
      Oxidized::API::Web.expects(:new).returns(mock_web)
      Oxidized::Core.any_instance.expects(:run)

      Oxidized::Core.new(nil)
    end
  end

  describe '#reload' do
    # Each test in this block creates a Core instance (run loop is stubbed) and
    # then exercises the private #reload method directly.
    # Plain Ruby objects are used for the worker in tests that need blocking
    # behaviour, since mocha stub blocks don't act as implementations.
    before do
      Oxidized::Core.any_instance.stubs(:run)
      @core = Oxidized::Core.new(nil)
      @core.instance_variable_set(:@reloading, false)
      @core.instance_variable_set(:@need_reload, true)
    end

    # Helper to install a plain worker whose #reload executes the given block
    def plain_worker(&block)
      w = Object.new
      w.define_singleton_method(:reload, &block)
      @core.instance_variable_set(:@worker, w)
      w
    end

    it 'returns immediately before the worker reload finishes (background thread)' do
      started = false
      mu = Mutex.new
      cv = ConditionVariable.new

      plain_worker do
        mu.synchronize do
          started = true
          cv.signal
        end
        sleep 0.15 # simulate a slow node-list fetch
      end

      start   = Time.now
      thread  = @core.send(:reload)
      elapsed = Time.now - start

      # Wait for the thread to have actually started before measuring
      mu.synchronize { cv.wait(mu, 2.0) until started }
      thread.join

      _(thread).must_be_kind_of Thread
      # #reload returned before the worker finished its 0.15 s sleep
      _(elapsed).must_be :<, 0.1
    end

    it 'sets @reloading to true while the reload thread is running' do
      in_reload  = false
      release_mu = Mutex.new
      release_cv = ConditionVariable.new
      released   = false

      plain_worker do
        release_mu.synchronize do
          in_reload = true
          release_cv.signal
          release_cv.wait(release_mu, 5.0) until released
        end
      end

      thread = @core.send(:reload)
      release_mu.synchronize { release_cv.wait(release_mu, 5.0) until in_reload }

      _(@core.instance_variable_get(:@reloading)).must_equal true

      release_mu.synchronize do
        released = true
        release_cv.signal
      end
      thread.join
    end

    it 'resets @reloading to false after the reload thread completes' do
      called = false
      plain_worker { called = true }

      thread = @core.send(:reload)
      thread.join

      _(called).must_equal true
      _(@core.instance_variable_get(:@reloading)).must_equal false
    end

    it 'resets @reloading to false even when the reload raises an exception' do
      plain_worker { raise 'source unreachable' }
      Oxidized::Core.logger.stubs(:error)

      thread = @core.send(:reload)
      thread.join

      _(@core.instance_variable_get(:@reloading)).must_equal false
    end

    it 'logs the exception message when reload raises' do
      plain_worker { raise 'source unreachable' }
      Oxidized::Core.logger.expects(:error).with(regexp_matches(/source unreachable/))

      thread = @core.send(:reload)
      thread.join
    end

    it 'clears @need_reload before starting the background thread' do
      plain_worker {}

      @core.send(:reload).join

      _(@core.instance_variable_get(:@need_reload)).must_equal false
    end

    it 'is a no-op when a reload is already in progress' do
      @core.instance_variable_set(:@reloading, true)
      called = false
      plain_worker { called = true }

      result = @core.send(:reload)

      _(result).must_be_nil
      _(called).must_equal false
      _(@core.instance_variable_get(:@need_reload)).must_equal true # unchanged
    end

    it 'allows a second reload after the first one finishes' do
      reload_count = 0
      mu           = Mutex.new
      plain_worker { mu.synchronize { reload_count += 1 } }

      thread1 = @core.send(:reload)
      thread1.join

      # Simulate a SIGHUP arriving after the first reload completes
      @core.instance_variable_set(:@need_reload, true)

      # Replace worker (plain_worker resets the ivar each call)
      plain_worker { mu.synchronize { reload_count += 1 } }
      thread2 = @core.send(:reload)
      thread2.join

      _(reload_count).must_equal 2
    end
  end
end
