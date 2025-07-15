require_relative 'spec_helper'

describe Oxidized::Logger do
  before(:each) do
    Oxidized.asetus = Asetus.new
    @saved_level = SemanticLogger.default_level
    # Remove the appender from spec_helper
    SemanticLogger.clear_appenders!
    # Reverse possible log level definition in spec_helper
    SemanticLogger.default_level = :info
  end

  after(:each) do
    SemanticLogger.clear_appenders!
    SemanticLogger.default_level = @saved_level
    SemanticLogger.add_appender(io: $stderr)
  end

  describe '#setup' do
    it 'creates an appender when no config is specified' do
      Oxidized::Logger.setup
      _(SemanticLogger.default_level).must_equal :info
      _(SemanticLogger.appenders.count).must_equal 1
      _(SemanticLogger.appenders[0]).must_be_instance_of SemanticLogger::Appender::IO
    end

    it 'creates an appender when only logger is specified' do
      Oxidized.asetus.cfg.logger = nil

      Oxidized::Logger.setup
      _(SemanticLogger.default_level).must_equal :info
      _(SemanticLogger.appenders.count).must_equal 1
      _(SemanticLogger.appenders[0]).must_be_instance_of SemanticLogger::Appender::IO
    end

    it 'creates an appender when only logger.level is specified' do
      Oxidized.asetus.cfg.logger.level = :debug
      Oxidized::Logger.setup

      _(SemanticLogger.default_level).must_equal :debug
      _(SemanticLogger.appenders.count).must_equal 1
    end

    it 'creates appenders as specified' do
      Oxidized.asetus.cfg.logger.appenders = [
        { 'type' => 'file', 'file' => '/dev/null' },
        { 'type' => 'stderr', 'level' => :warn },
        { 'type' => 'syslog' }
      ]

      Oxidized::Logger.setup

      _(SemanticLogger.appenders.count).must_equal 3
      _(SemanticLogger.appenders[0]).must_be_instance_of SemanticLogger::Appender::File
      # Appender get default level trace, so that they use the default level of SemanticLogger
      _(SemanticLogger.appenders[0].level).must_equal :trace
      _(SemanticLogger.appenders[1]).must_be_instance_of SemanticLogger::Appender::IO
      _(SemanticLogger.appenders[1].level).must_equal :warn
      _(SemanticLogger.appenders[2]).must_be_instance_of SemanticLogger::Appender::Syslog
    end

    it 'creates an appender when legacy use_syslog is true' do
      Oxidized.asetus.cfg.use_syslog = true
      Oxidized::Logger.logger.expects(:warn)
                      .with("The configuration 'use_syslog' is deprecated. " \
                            "Remove it and use 'logger' instead")
      Oxidized::Logger.setup

      _(SemanticLogger.appenders.count).must_equal 1
      _(SemanticLogger.appenders[0]).must_be_instance_of SemanticLogger::Appender::Syslog
    end

    it 'Set loglevel to debug when config.debug is true' do
      _(SemanticLogger.default_level).must_equal :info
      Oxidized.asetus.cfg.debug = true
      Oxidized::Logger.setup

      _(SemanticLogger.default_level).must_equal :debug
      _(SemanticLogger.appenders[0]).must_be_instance_of SemanticLogger::Appender::IO
    end

    it 'Use a File appender when legacy log is set' do
      Oxidized.asetus.cfg.log = File::NULL
      Oxidized::Logger.logger.expects(:warn)
                      .with("The configuration 'log' is deprecated. " \
                            "Remove it and use 'logger' instead")
      Oxidized::Logger.setup

      _(SemanticLogger.appenders[0]).must_be_instance_of SemanticLogger::Appender::File
    end

    it 'Overrides log when legacy use_syslog is set' do
      Oxidized.asetus.cfg.log = File::NULL
      Oxidized.asetus.cfg.use_syslog = true
      Oxidized::Logger.logger.expects(:warn)
                      .with("The configuration 'use_syslog' is deprecated. " \
                            "Remove it and use 'logger' instead")
      Oxidized::Logger.setup

      _(SemanticLogger.appenders.count).must_equal 1
      _(SemanticLogger.appenders[0]).must_be_instance_of SemanticLogger::Appender::Syslog
    end

    it 'keeps specified :trace when debug = true' do
      Oxidized.asetus.cfg.logger.level = :trace
      Oxidized.asetus.cfg.debug = true
      Oxidized::Logger.setup

      _(SemanticLogger.default_level).must_equal :trace
    end
  end

  describe '#add_appender' do
    before(:each) do
      Asetus.any_instance.expects(:load)
      Asetus.any_instance.expects(:create).returns(false)
      # Set :home_dir to make sure the OXIDIZED_HOME environment variable is not used
      Oxidized::Config.load({ home_dir: '/cfg_path/' })
    end

    it 'raises an InvalidConfig when the appender type is unknown' do
      err = _ { Oxidized::Logger.add_appender('type' => 'invalid') }.must_raise Oxidized::InvalidConfig
      _(err.message).must_equal 'Unknown logger invalid, edit /cfg_path/config'
    end
  end
end
