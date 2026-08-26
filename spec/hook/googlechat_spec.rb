require_relative '../spec_helper'
require 'oxidized/hook/googlechat'

describe GoogleChat do
  let(:gc) { GoogleChat.new }

  before do
    Oxidized.asetus = Asetus.new

    Oxidized.config.hooks.google_chat.type = 'googlechat'
    Oxidized.config.hooks.google_chat.webhook_url =
      'https://chat.example.test/webhook'

    gc.cfg = Oxidized.config.hooks.google_chat
  end

  # ==========================================================
  # CONFIGURATION VALIDATION
  # ==========================================================

  describe '#validate_cfg!' do
    it 'accepts valid configuration' do
      _(gc.validate_cfg!).must_be_nil
    end

    it 'raises an error when webhook_url is not configured' do
      gc.expects(:respond_to?)
        .with(:validate_cfg!)
        .returns(false)

      Oxidized.config.hooks.google_chat = {
        type: 'googlechat'
      }

      gc.cfg = Oxidized.config.hooks.google_chat

      _ { gc.validate_cfg! }.must_raise(KeyError)
    end

    it 'raises an error when webhook_url is empty' do
      Oxidized.config.hooks.google_chat.webhook_url = ''

      _ { gc.validate_cfg! }.must_raise(ArgumentError)
    end

    it 'raises an error when webhook_url is invalid' do
      Oxidized.config.hooks.google_chat.webhook_url = 'not-a-url'

      _ { gc.validate_cfg! }.must_raise(ArgumentError)
    end

    it 'requires librenms_api and librenms_token together' do
      Oxidized.config.hooks.google_chat.librenms_api =
        'http://librenms/api/v0/devices'

      _ { gc.validate_cfg! }.must_raise(ArgumentError)
    end

    it 'accepts LibreNMS configuration when URL and token are present' do
      Oxidized.config.hooks.google_chat.librenms_api =
        'http://librenms/api/v0/devices'
      Oxidized.config.hooks.google_chat.librenms_token = 'test-token'

      _(gc.validate_cfg!).must_be_nil
    end

    it 'rejects a max_diff_chars value less than 1' do
      Oxidized.config.hooks.google_chat.max_diff_chars = 0

      _ { gc.validate_cfg! }.must_raise(ArgumentError)
    end

    it 'rejects a negative librenms_cache_ttl' do
      Oxidized.config.hooks.google_chat.librenms_cache_ttl = -1

      _ { gc.validate_cfg! }.must_raise(ArgumentError)
    end

    it 'rejects a negative failure_cooldown' do
      Oxidized.config.hooks.google_chat.failure_cooldown = -1

      _ { gc.validate_cfg! }.must_raise(ArgumentError)
    end
  end

  # ==========================================================
  # LIBRENMS DISPLAY NAME
  # ==========================================================

  describe '#lookup_display_name' do
    let(:node) do
      stub(
        name:  '10.100.0.1',
        ip:    '10.100.0.1',
        group: 'switches'
      )
    end

    before do
      Oxidized.config.hooks.google_chat.librenms_api =
        'http://librenms/api/v0/devices'
      Oxidized.config.hooks.google_chat.librenms_token = 'test-token'

      gc.cfg = Oxidized.config.hooks.google_chat
    end

    it 'uses LibreNMS sysName when available' do
      devices = [
        {
          'ip'       => '10.100.0.1',
          'hostname' => '10.100.0.1',
          'sysName'  => 'DataCenter-Core'
        }
      ]

      gc.expects(:librenms_devices).returns(devices)

      result = gc.send(:lookup_display_name, node)

      _(result).must_equal 'DataCenter-Core'
    end

    it 'falls back to the IP when sysName is empty' do
      devices = [
        {
          'ip'       => '10.100.0.1',
          'hostname' => '10.100.0.1',
          'sysName'  => ''
        }
      ]

      gc.expects(:librenms_devices).returns(devices)

      result = gc.send(:lookup_display_name, node)

      _(result).must_equal '10.100.0.1'
    end

    it 'falls back to the IP when sysName is missing' do
      devices = [
        {
          'ip'       => '10.100.0.1',
          'hostname' => '10.100.0.1'
        }
      ]

      gc.expects(:librenms_devices).returns(devices)

      result = gc.send(:lookup_display_name, node)

      _(result).must_equal '10.100.0.1'
    end

    it 'falls back to the IP when the device is not found' do
      devices = [
        {
          'ip'       => '10.200.0.1',
          'hostname' => '10.200.0.1',
          'sysName'  => 'Another-Switch'
        }
      ]

      gc.expects(:librenms_devices).returns(devices)

      result = gc.send(:lookup_display_name, node)

      _(result).must_equal '10.100.0.1'
    end

    it 'falls back to the IP when LibreNMS is unavailable' do
      gc.expects(:librenms_devices).returns(nil)

      result = gc.send(:lookup_display_name, node)

      _(result).must_equal '10.100.0.1'
    end

    it 'uses the node IP when LibreNMS integration is not configured' do
      Oxidized.config.hooks.google_chat.librenms_api = nil
      Oxidized.config.hooks.google_chat.librenms_token = nil

      result = gc.send(:lookup_display_name, node)

      _(result).must_equal '10.100.0.1'
    end
  end

  # ==========================================================
  # DIFF FORMATTING
  # ==========================================================

  describe '#format_diff' do
    it 'colors added lines green' do
      result = gc.send(:format_diff, "+hostname new-name\n")

      _(result).must_include '#00C853'
      _(result).must_include '+hostname new-name'
    end

    it 'colors removed lines red' do
      result = gc.send(:format_diff, "-hostname old-name\n")

      _(result).must_include '#D50000'
      _(result).must_include '-hostname old-name'
    end

    it 'colors other lines gray' do
      result = gc.send(:format_diff, " hostname unchanged\n")

      _(result).must_include '#9E9E9E'
    end

    it 'HTML escapes configuration content' do
      result = gc.send(:format_diff, "+description <core> & uplink\n")

      _(result).must_include '&lt;core&gt;'
      _(result).must_include '&amp;'
      _(result).wont_include '<core>'
    end
  end

  # ==========================================================
  # DIFF TRUNCATION
  # ==========================================================

  describe '#truncate_diff' do
    it 'does not truncate a diff within the limit' do
      Oxidized.config.hooks.google_chat.max_diff_chars = 100

      result = gc.send(:truncate_diff, 'short diff')

      _(result).must_equal 'short diff'
    end

    it 'truncates a diff that exceeds the configured limit' do
      Oxidized.config.hooks.google_chat.max_diff_chars = 10

      result = gc.send(
        :truncate_diff,
        'abcdefghijklmnopqrstuvwxyz'
      )

      _(result).must_include 'abcdefghij'
      _(result).must_include '[truncated...]'
      _(result).wont_include 'klmnopqrstuvwxyz'
    end
  end

  # ==========================================================
  # NODE FAILURE
  # ==========================================================

  describe '#node_fail' do
    let(:node) do
      stub(
        name:       '10.100.0.1',
        ip:         '10.100.0.1',
        group:      'switches',
        err_reason: 'Connection refused',
        err_type:   'Errno::ECONNREFUSED'
      )
    end

    let(:ctx) do
      Oxidized::HookManager::HookContext.new(
        event: :node_fail,
        node:  node
      )
    end

    it 'sends a plain-text failure notification' do
      gc.expects(:lookup_display_name)
        .with(node)
        .returns('DataCenter-Core')

      expected_text =
        'Config check failed on DataCenter-Core (10.100.0.1). Connection refused'

      gc.expects(:send_google_chat).with({
                                           text: expected_text
                                         })

      gc.run_hook(ctx)
    end

    it 'falls back to the IP in the failure notification' do
      gc.expects(:lookup_display_name)
        .with(node)
        .returns('10.100.0.1')

      gc.expects(:send_google_chat).with({
                                           text: 'Config check failed on 10.100.0.1 (10.100.0.1). Connection refused'
                                         })

      gc.run_hook(ctx)
    end

    it 'optionally includes the error type' do
      Oxidized.config.hooks.google_chat.show_error_type = true

      gc.expects(:lookup_display_name)
        .with(node)
        .returns('DataCenter-Core')

      expected_text =
        'Config check failed on DataCenter-Core (10.100.0.1). ' \
        'Connection refused [Errno::ECONNREFUSED]'

      gc.expects(:send_google_chat).with({
                                           text: expected_text
                                         })

      gc.run_hook(ctx)
    end
  end

  # ==========================================================
  # FAILURE COOLDOWN
  # ==========================================================

  describe '#failure_cooldown' do
    let(:node) do
      stub(
        name:       '10.100.0.1',
        ip:         '10.100.0.1',
        group:      'switches',
        err_reason: 'Connection refused',
        err_type:   'Errno::ECONNREFUSED'
      )
    end

    let(:ctx) do
      Oxidized::HookManager::HookContext.new(
        event: :node_fail,
        node:  node
      )
    end

    it 'suppresses repeated failure notifications during cooldown' do
      Oxidized.config.hooks.google_chat.failure_cooldown = 3600

      gc.stubs(:lookup_display_name).returns('DataCenter-Core')

      gc.expects(:send_google_chat).once

      gc.run_hook(ctx)
      gc.run_hook(ctx)
    end

    it 'does not suppress failures when cooldown is disabled' do
      Oxidized.config.hooks.google_chat.failure_cooldown = 0

      gc.stubs(:lookup_display_name).returns('DataCenter-Core')

      gc.expects(:send_google_chat).twice

      gc.run_hook(ctx)
      gc.run_hook(ctx)
    end
  end

  # ==========================================================
  # POST STORE
  # ==========================================================

  describe '#post_store' do
    let(:node) do
      stub(
        name:  '10.100.0.1',
        ip:    '10.100.0.1',
        group: 'switches'
      )
    end

    let(:ctx) do
      Oxidized::HookManager::HookContext.new(
        event:     :post_store,
        node:      node,
        commitref: 'abc123'
      )
    end

    it 'sends a Google Chat card containing the configuration diff' do
      gc.expects(:lookup_display_name)
        .with(node)
        .returns('DataCenter-Core')

      gc.expects(:get_diff)
        .with(ctx)
        .returns("+hostname new-name\n-hostname old-name\n")

      gc.expects(:send_google_chat).with do |payload|
        cards = payload[:cards]

        next false unless cards.is_a?(Array)
        next false if cards.empty?

        card = cards.first
        header = card[:header]

        next false unless header[:subtitle] ==
                          'DataCenter-Core (10.100.0.1)'

        diff_text =
          card[:sections][0][:widgets][1][:textParagraph][:text]

        diff_text.include?('hostname new-name') &&
          diff_text.include?('hostname old-name') &&
          diff_text.include?('#00C853') &&
          diff_text.include?('#D50000')
      end

      gc.run_hook(ctx)
    end

    it 'does not send a notification when no diff is available' do
      gc.expects(:lookup_display_name)
        .with(node)
        .returns('DataCenter-Core')

      gc.expects(:get_diff)
        .with(ctx)
        .returns(nil)

      gc.expects(:send_google_chat).never

      gc.run_hook(ctx)
    end
  end

  # ==========================================================
  # UNSUPPORTED EVENTS
  # ==========================================================

  describe '#unsupported_event' do
    it 'does not send a notification for an unsupported event' do
      node = stub(
        name:  '10.100.0.1',
        ip:    '10.100.0.1',
        group: 'switches'
      )

      ctx = Oxidized::HookManager::HookContext.new(
        event: :node_success,
        node:  node
      )

      gc.expects(:send_google_chat).never

      gc.run_hook(ctx)
    end
  end
end
