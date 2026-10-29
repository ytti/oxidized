require_relative 'spec_helper'
require 'oxidized/worker'

describe 'bounded manual backup queue' do
  before do
    Resolv.any_instance.stubs(:getaddress)
    Oxidized.asetus = Asetus.new
    Oxidized::Node.any_instance.stubs(:resolve_repo)
    Oxidized::Node.any_instance.stubs(:resolve_output)
    @items = %w[one two three].map do |name|
      Oxidized::Node.new(name: name, model: 'junos', input: 'ssh', output: 'git')
    end
    @nodes = Oxidized::Nodes.new(nodes: @items)
    @jobs = mock('jobs')
    @jobs.expects(:increment).never
    @nodes.jobs = @jobs
  end

  it 'queues the complete inventory without increasing concurrency and rejects duplicates' do
    first = @nodes.queue_backups
    _(first.length).must_equal 3
    _(first.map { |row| row[:state] }.uniq).must_equal ['queued']
    _(@nodes.queue_backups).must_equal first.reverse
    _(@nodes.size).must_equal 3
  end

  it 'validates every selected name before mutating the queue' do
    _(proc { @nodes.queue_backups(%w[one missing]) }).must_raise Oxidized::NodeNotFound
    _(@nodes.backup_status.map { |row| row[:state] }.uniq).must_equal ['not_requested']
  end

  it 'tracks running and finished collection results independently of revisions' do
    @nodes.queue_backups(['one'])
    node = @items.first
    node.running = true
    node.nexted = false
    _(@nodes.backup_status.find { |row| row[:name] == 'one' }[:state]).must_equal 'running'
    node.last = Oxidized::Node::JobStruct.new(Time.now - 1, Time.now, :success, 1)
    node.running = false
    @nodes.finish_manual_backup(node)
    state = @nodes.backup_status.find { |row| row[:name] == 'one' }
    _(state[:state]).must_equal 'succeeded'
    _(state[:last_attempt_at]).must_equal node.last.end
    @nodes.queue_backups(['one'])
    node.nexted = false
    node.last = Oxidized::Node::JobStruct.new(Time.now - 1, Time.now, :no_connection, 1)
    @nodes.finish_manual_backup(node)
    _(@nodes.backup_status.find { |row| row[:name] == 'one' }[:state]).must_equal 'failed'
  end

  it 'does not invent completion after process restart' do
    @nodes.queue_backups(['one'])
    restarted = Oxidized::Nodes.new(nodes: [])
    _(restarted.backup_status).must_equal []
  end
  it 'atomically dispatches a queued node and suppresses duplicate requests while running' do
    Oxidized.config.interval = 0
    @nodes.queue_backups(['one'])
    node = @nodes.next_job
    _(node.name).must_equal 'one'
    _(node.running?).must_equal true
    _(node.nexted?).must_equal false
    _(@nodes.queue_backups(['one']).first[:state]).must_equal 'running'
    _(@nodes.next_job).must_be_nil
  end

  it 'keeps retried jobs pending and ignores completion from a replaced node' do
    @nodes.queue_backups(['one'])
    node = @items.first
    node.last = Oxidized::Node::JobStruct.new(Time.now - 1, Time.now, :no_connection, 1)
    node.nexted = true
    @nodes.finish_manual_backup(node)
    _(@nodes.backup_status.find { |row| row[:name] == 'one' }[:state]).must_equal 'queued'
    replacement = node.dup
    @nodes.replace([replacement])
    node.nexted = false
    @nodes.finish_manual_backup(node)
    _(@nodes.backup_status.first[:state]).must_equal 'unknown'
  end

  it 'keeps a retry pending and reports success only after Worker finishes storage' do
    Oxidized.config.retries = 1
    Oxidized.config.next_adds_job = false
    hooks = mock('hooks')
    hooks.expects(:node_success).once
    Oxidized.stubs(:hooks).returns(hooks)
    @jobs.expects(:duration).twice
    worker = Oxidized::Worker.allocate
    worker.instance_variable_set(:@nodes, @nodes)
    worker.instance_variable_set(:@jobs, @jobs)
    worker.instance_variable_set(:@jobs_done, 0)
    node = @items.first
    @nodes.queue_backups(['one'])
    job_type = Struct.new(:node, :status, :start, :end, :time, :config)
    worker.process(job_type.new(node, :no_connection, Time.now - 1, Time.now, 1, nil))
    _(@nodes.backup_status.find { |row| row[:name] == 'one' }[:state]).must_equal 'queued'
    _(node.retry).must_equal 1

    entered = Queue.new
    release = Queue.new
    output = Object.new
    output.define_singleton_method(:store) do |*_args, **_options|
      entered << true
      release.pop
      false # unchanged configuration: successful collection, no new revision
    end
    factory = Object.new
    factory.define_singleton_method(:new) { output }
    node.stubs(:output).returns(factory)
    node.nexted = false
    task = Thread.new do
      worker.process(job_type.new(node, :success, Time.now - 1, Time.now, 1, 'same configuration'))
    end
    begin
      Timeout.timeout(5) { entered.pop }
      _(@nodes.backup_status.find { |row| row[:name] == 'one' }[:state]).must_equal 'queued'
    ensure
      release << true
      task.join(5)
    end
    _(task.alive?).must_equal false
    _(@nodes.backup_status.find { |row| row[:name] == 'one' }[:state]).must_equal 'succeeded'
  end
end
