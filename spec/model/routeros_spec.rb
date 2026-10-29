require_relative 'model_helper'
require_relative '../output/git_helper'

describe 'Model RouterOS export normalization' do
  include GitHelper

  before do
    init_model_helper
    @repo_path = File.join(@tmpdir, 'routeros.git')
    @repo = init_repo(@repo_path)
    @node = Oxidized::Node.new(name: 'routeros-test', ip: '192.0.2.10', input: 'ssh', model: 'routeros')
  end

  def backup(version:, export:)
    export_command = version.to_s.start_with?('6') ? "/export\n" : "/export show-sensitive\n"
    simulation = {
      'init_prompt' => '[admin@router] > ',
      'commands'    => {
        "quit\n"                                 => '',
        "/system resource print\n"               => " version: #{version} (stable)\r\n platform: MikroTik\r\n",
        "/system package update print\n"         => " installed-version: #{version}\r\n",
        "/system history print without-paging\n" => "Flags: U - UNDOABLE\n\n",
        export_command                           => export
      }
    }
    Net::SSH.stubs(:start).returns(MockSsh.new(simulation))
    status, outputs = @node.run
    _(status).must_equal :success
    outputs
  end

  def store(outputs)
    content = outputs.to_cfg
    previous = @repo.empty? ? nil : @repo.blob_at(@repo.head.target_id, @node.name).content
    commit_files(@repo, { @node.name => content }, message: 'RouterOS backup') unless content == previous
    Oxidized::Output::Git.hash_list(@node.name, @repo_path)
  end

  def routeros_export(header:, address:, line_ending: "\n", indent: '', note: nil)
    lines = ["#{indent}# #{header}", '/interface ethernet', 'set [ find default-name=ether1 ] comment=uplink',
             '/ip address', "add address=#{address} interface=ether1", '/ip firewall filter',
             'add chain=input action=accept comment=allow-management']
    lines.insert(1, "##{note}") if note
    lines.join(line_ending) + line_ending
  end

  it 'does not create Git revisions for identical backups or RouterOS 6 timestamp-only changes' do
    export = routeros_export(
      header: 'oct/24/2026 11:54:57 by RouterOS 6.49.17',
      address: '192.0.2.1/24', note: ' 2026-10-24 maintenance note'
    )
    first = backup(version: '6.49.17', export: export)
    initial_history = store(first)
    first_oid = initial_history.first[:oid]

    identical = backup(version: '6.49.17', export: export)
    _(identical.to_cfg).must_equal first.to_cfg
    _(store(identical).map { |revision| revision[:oid] }).must_equal [first_oid]

    timestamp_only_export = routeros_export(
      header: 'oct/24/2026 12:04:57 by RouterOS 6.49.17',
      address: '192.0.2.1/24', line_ending: "\r\n", indent: '  ',
      note: ' 2026-10-24 maintenance note'
    )
    timestamp_only = backup(version: '6.49.17', export: timestamp_only_export)
    _(timestamp_only.to_cfg).must_equal first.to_cfg
    3.times do
      repeated = backup(version: '6.49.17', export: timestamp_only_export)
      _(repeated.to_cfg).must_equal first.to_cfg
      _(store(repeated).map { |revision| revision[:oid] }).must_equal [first_oid]
    end
    _(Rugged::Repository.new(@repo_path).head.target.parent_ids).must_equal []
  end

  it 'normalizes RouterOS 7 ISO timestamps with leading whitespace and CRLF' do
    first = backup(
      version: '7.24.5',
      export:  routeros_export(
        header: '2026-10-24 11:54:57 by RouterOS 7.24.5', address: '192.0.2.1/24'
      )
    )
    changed_timestamp = backup(
      version: '7.24.5',
      export:  routeros_export(
        header: '2026-10-24 12:04:57 by RouterOS 7.24.5', address: '192.0.2.1/24',
        line_ending: "\r\n", indent: '  '
      )
    )

    _(changed_timestamp.to_cfg).must_equal first.to_cfg
    _(store(first).length).must_equal 1
    _(store(changed_timestamp).length).must_equal 1
  end

  it 'does not create a revision when only the export line endings differ' do
    lf = routeros_export(header: '2026-10-29 17:22:58 by RouterOS 7.25', address: '192.0.2.1/24')
    crlf = lf.gsub("\n", "\r\n")
    first = backup(version: '7.25', export: lf)
    _(store(first).length).must_equal 1
    second = backup(version: '7.25', export: crlf)
    _(second.to_cfg).must_equal first.to_cfg
    _(store(second).length).must_equal 1
  end

  it 'creates one isolated Git revision for a firewall rule change' do
    initial = routeros_export(header: '2026-10-29 17:22:58 by RouterOS 7.25', address: '192.0.2.1/24')
    first = backup(version: '7.25', export: initial)
    store(first)
    changed = backup(version: '7.25', export: initial.sub('action=accept', 'action=drop'))
    _(changed.to_cfg).wont_equal first.to_cfg
    _(store(changed).length).must_equal 2
  end

  it 'creates one isolated Git revision for an interface configuration change' do
    initial = routeros_export(header: '2026-10-29 17:22:58 by RouterOS 7.25', address: '192.0.2.1/24')
    first = backup(version: '7.25', export: initial)
    store(first)
    changed = backup(version: '7.25', export: initial.sub('comment=uplink', 'comment=core-uplink'))
    _(changed.to_cfg).wont_equal first.to_cfg
    _(store(changed).length).must_equal 2
  end

  it 'creates revisions for real configuration changes and meaningful RouterOS version changes' do
    first = backup(
      version: '7.24.5',
      export:  routeros_export(
        header: '2026-10-24 11:54:57 by RouterOS 7.24.5', address: '192.0.2.1/24'
      )
    )
    original_history = store(first)

    config_change = backup(
      version: '7.24.5',
      export:  routeros_export(
        header: '2026-10-24 12:04:57 by RouterOS 7.24.5', address: '192.0.2.2/24'
      )
    )
    _(config_change.to_cfg).wont_equal first.to_cfg
    config_history = store(config_change)
    _(config_history.length).must_equal 2
    _(config_history.map { |revision| revision[:oid] }).must_include original_history.first[:oid]

    firmware_change = backup(
      version: '7.24.6',
      export:  routeros_export(
        header: '2026-10-24 12:14:57 by RouterOS 7.24.6', address: '192.0.2.2/24'
      )
    )
    _(firmware_change.to_cfg).wont_equal config_change.to_cfg
    firmware_history = store(firmware_change)
    _(firmware_history.length).must_equal 3
    _(firmware_history.map { |revision| revision[:oid] }).must_include original_history.first[:oid]
  end
end
