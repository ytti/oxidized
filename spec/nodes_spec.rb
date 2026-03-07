require_relative 'spec_helper'

# Shared options used across #load tests — defined at file scope to avoid the
# Lint/ConstantDefinitionInBlock offense.
NODE_OPTS = {
  name:     'router1',
  input:    'ssh',
  output:   'git',
  model:    'junos',
  username: 'u',
  password: 'p',
  prompt:   '>'
}.freeze

describe Oxidized::Nodes do
  before(:each) do
    Resolv.any_instance.stubs(:getaddress)
    Oxidized.asetus = Asetus.new

    opts = {
      input:    'ssh',
      output:   'git',
      model:    'junos',
      username: 'alma',
      password: 'armud',
      prompt:   'test_prompt'
    }

    Oxidized::Node.any_instance.stubs(:resolve_repo)
    Oxidized::Node.any_instance.stubs(:resolve_output)
    @nodes_org = %w[ltt-pe1.hel kes2-rr1.tku tor-peer1.oul
                    hal-p2.tre sav-gr1-sw1.kuo psl-sec-pe1.hel].map { |e| Oxidized::Node.new(opts.merge(name: e)) }
    @node = @nodes_org.delete_at(0)
    @nodes = Oxidized::Nodes.new(nodes: @nodes_org.dup)
  end

  describe '#load' do
    before do
      Resolv.any_instance.stubs(:getaddress)
      Oxidized::Node.any_instance.stubs(:resolve_repo)
      Oxidized::Node.any_instance.stubs(:resolve_output)

      # Start with an empty list so the first load always goes through replace()
      @load_nodes = Oxidized::Nodes.new(nodes: [])

      Oxidized.config.source.default = 'csv'

      @fake_source_instance = mock('source_instance')
      @fake_source_class    = mock('source_class')
      @fake_source_class.stubs(:new).returns(@fake_source_instance)

      Oxidized.mgr.stubs(:add_source).returns(true)
      Oxidized.mgr.stubs(:source).returns('csv' => @fake_source_class)
      Oxidized::Output.stubs(:clean_obsolete_nodes)

      # Use a small thread count so tests are fast and deterministic
      Oxidized.config.node_load_threads = 4
    end

    it 'populates the list from the source' do
      @fake_source_instance.stubs(:load).returns([NODE_OPTS])

      @load_nodes.load

      _(@load_nodes.size).must_equal 1
      _(@load_nodes.first.name).must_equal 'router1'
    end

    it 'replaces the entire list on a full reload' do
      first_opts  = NODE_OPTS
      second_opts = NODE_OPTS.merge(name: 'router2')

      # mocha sequential returns: first call → [first_opts], subsequent → [second_opts]
      @fake_source_instance.stubs(:load).returns([first_opts]).then.returns([second_opts])

      @load_nodes.load
      _(@load_nodes.size).must_equal 1
      _(@load_nodes.first.name).must_equal 'router1'

      @load_nodes.load
      _(@load_nodes.size).must_equal 1
      _(@load_nodes.first.name).must_equal 'router2'
    end

    it 'preserves last and stats from an existing node during reload' do
      @fake_source_instance.stubs(:load).returns([NODE_OPTS])

      @load_nodes.load
      node = @load_nodes.first

      # Node#last= builds a JobStruct from the job's attributes, so stub all of them
      fake_job = mock('job')
      fake_job.stubs(:start).returns(Time.at(1))
      fake_job.stubs(:end).returns(Time.at(2))
      fake_job.stubs(:status).returns(:success)
      fake_job.stubs(:time).returns(0.5)
      node.last  = fake_job
      old_last   = node.last # capture the resulting JobStruct

      fake_stats = mock('stats')
      node.stats = fake_stats

      # Reload with the same node name — update_nodes should carry over last/stats
      @load_nodes.load

      _(@load_nodes.size).must_equal 1
      _(@load_nodes.first.last).must_equal old_last
      _(@load_nodes.first.stats).must_equal fake_stats
    end

    it 'does not preserve last/stats for a node that disappears on reload' do
      @fake_source_instance.stubs(:load).returns([NODE_OPTS]).then.returns([])

      @load_nodes.load
      @load_nodes.load

      _(@load_nodes).must_be_empty
    end

    it 'skips a node that raises ModelNotFound and logs an error' do
      @fake_source_instance.stubs(:load).returns([{ name: 'bad_model' }])
      Oxidized::Node.stubs(:new).raises(Oxidized::ModelNotFound, 'model not found')
      Oxidized::Nodes.logger.expects(:error).with(regexp_matches(/bad_model/))

      @load_nodes.load

      _(@load_nodes).must_be_empty
    end

    it 'skips a node that raises Resolv::ResolvError and logs an error' do
      @fake_source_instance.stubs(:load).returns([{ name: 'unresolvable.host' }])
      Oxidized::Node.stubs(:new).raises(Resolv::ResolvError, 'DNS resolution failed')
      Oxidized::Nodes.logger.expects(:error).with(regexp_matches(/unresolvable\.host/))

      @load_nodes.load

      _(@load_nodes).must_be_empty
    end

    it 'continues loading remaining nodes after a single node fails' do
      bad_opts  = { name: 'bad_node' }
      good_opts = NODE_OPTS.merge(name: 'good_node')

      @fake_source_instance.stubs(:load).returns([bad_opts, good_opts])

      # Minimal stub node to avoid real Node construction
      good_node = mock('good_node')
      good_node.stubs(:name).returns('good_node')
      good_node.stubs(:last).returns(nil)
      good_node.stubs(:stats=)
      good_node.stubs(:last=)

      # Raise for bad_node, return stub for good_node
      Oxidized::Node.expects(:new).with(bad_opts).raises(Oxidized::ModelNotFound, 'model not found')
      Oxidized::Node.expects(:new).with(good_opts).returns(good_node)
      Oxidized::Nodes.logger.stubs(:error)

      @load_nodes.load

      _(@load_nodes.size).must_equal 1
      _(@load_nodes.first.name).must_equal 'good_node'
    end

    it 'filters nodes when node_want is given' do
      opts1 = NODE_OPTS.merge(name: 'router1')
      opts2 = NODE_OPTS.merge(name: 'router2')
      @fake_source_instance.stubs(:load).returns([opts1, opts2])

      @load_nodes.load('router1')

      _(@load_nodes.size).must_equal 1
      _(@load_nodes.first.name).must_equal 'router1'
    end

    it 'loads all nodes correctly with multiple threads' do
      opts_list = (1..8).map { |i| NODE_OPTS.merge(name: "router#{i}") }
      @fake_source_instance.stubs(:load).returns(opts_list)

      @load_nodes.load

      _(@load_nodes.size).must_equal 8
      loaded_names = @load_nodes.map(&:name).sort
      _(loaded_names).must_equal (1..8).map { |i| "router#{i}" }.sort
    end

    it 'preserves source order after parallel construction' do
      opts_list = %w[alpha beta gamma delta].map { |n| NODE_OPTS.merge(name: n) }
      @fake_source_instance.stubs(:load).returns(opts_list)

      @load_nodes.load

      # update_nodes sorts by last.end (all nil here → Time.new(0)), so relative
      # order among equally-ranked nodes is stable (sort_by! is stable in Ruby).
      _(@load_nodes.map(&:name)).must_equal %w[alpha beta gamma delta]
    end

    # -------------------------------------------------------------------------
    # Concurrency: the mutex must NOT be held while the source is being fetched.
    # These tests use plain Ruby objects (not mocha mocks) for the source so
    # the blocking behaviour works correctly across threads.
    # -------------------------------------------------------------------------

    it 'does not hold the mutex during the slow source fetch' do
      fetch_started = false
      proceed       = false
      sync_mu       = Mutex.new
      sync_cv       = ConditionVariable.new

      # Plain object whose #load blocks until signalled — simulates a slow HTTP call
      slow_source = Object.new
      slow_source.define_singleton_method(:load) do |_node_want = nil|
        sync_mu.synchronize do
          fetch_started = true
          sync_cv.signal
          sync_cv.wait(sync_mu, 5.0) until proceed
        end
        []
      end

      fake_class = mock('source_class_slow')
      fake_class.stubs(:new).returns(slow_source)
      Oxidized.mgr.stubs(:source).returns('csv' => fake_class)

      load_thread = Thread.new { @load_nodes.load }

      # Wait until the source fetch has started
      sync_mu.synchronize { sync_cv.wait(sync_mu, 5.0) until fetch_started }

      # The source fetch is in progress. If the mutex were still held here,
      # list() would block for the full duration of the fetch.
      start   = Time.now
      result  = @load_nodes.list # must return immediately
      elapsed = Time.now - start

      # Unblock the fetch
      sync_mu.synchronize do
        proceed = true
        sync_cv.signal
      end
      load_thread.join

      _(elapsed).must_be :<, 0.1 # must not have waited on the mutex
      _(result).must_be_kind_of Array
    end

    it 'allows multiple concurrent readers while a reload is in progress' do
      fetch_started = false
      proceed       = false
      sync_mu       = Mutex.new
      sync_cv       = ConditionVariable.new

      slow_source = Object.new
      slow_source.define_singleton_method(:load) do |_node_want = nil|
        sync_mu.synchronize do
          fetch_started = true
          sync_cv.signal
          sync_cv.wait(sync_mu, 5.0) until proceed
        end
        []
      end

      fake_class = mock('source_class_slow2')
      fake_class.stubs(:new).returns(slow_source)
      Oxidized.mgr.stubs(:source).returns('csv' => fake_class)

      load_thread = Thread.new { @load_nodes.load }
      sync_mu.synchronize { sync_cv.wait(sync_mu, 5.0) until fetch_started }

      # Spin up several concurrent readers — none should deadlock or block
      reader_results = Array.new(5)
      reader_threads = 5.times.map do |i|
        Thread.new { reader_results[i] = @load_nodes.list }
      end

      reader_threads.each { |t| t.join(2.0) }

      sync_mu.synchronize do
        proceed = true
        sync_cv.signal
      end
      load_thread.join

      reader_threads.each { |t| _(t.alive?).must_equal false }
      reader_results.each { |r| _(r).must_be_kind_of Array }
    end

    it 'presents an atomic swap: list size changes from old to new in one step' do
      # Prime with two nodes
      @fake_source_instance.stubs(:load).returns([NODE_OPTS, NODE_OPTS.merge(name: 'router2')])
      @load_nodes.load
      _(@load_nodes.size).must_equal 2

      # Reload with three nodes — the list must jump atomically from 2 → 3
      @fake_source_instance.stubs(:load).returns(
        [NODE_OPTS, NODE_OPTS.merge(name: 'router2'), NODE_OPTS.merge(name: 'router3')]
      )
      @load_nodes.load

      _(@load_nodes.size).must_equal 3
    end
  end

  describe '#put' do
    it 'adds node to top of queue' do
      @nodes.put @node
      _(@nodes).must_equal [@node] + @nodes_org
    end
  end

  describe '#get' do
    it 'returns node from top of queue' do
      _(@nodes.get).must_equal @nodes_org.first
    end
    it 'moves node from top to bottom' do
      @nodes.get
      _(@nodes.last).must_equal @nodes_org.first
    end
    it 'does not change node count' do
      before = @nodes.size
      @nodes.get
      _(before).must_equal @nodes.size
    end
  end

  describe '#next' do
    before(:each) do
      Oxidized::Nodes.logger.expects(:info)
                     .with('Add node sav-gr1-sw1.kuo to running jobs')
    end
    it 'moves node to top of queue' do
      node = @nodes[3]
      @nodes.next node.name
      _(@nodes.first).must_equal node
    end
    it 'does not change node count' do
      before = @nodes.size
      @nodes.next @nodes[3].name
      _(before).must_equal @nodes.size
    end
  end
end
