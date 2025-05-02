require_relative 'spec_helper'

describe Oxidized do
  describe '#setup_logger' do
    before(:each) do
      # Reset SemanticLogger settings changed by other tests
      SemanticLogger.clear_appenders!
      SemanticLogger.default_level = :info
      Oxidized.asetus = Asetus.new
    end

    after(:each) do
      SemanticLogger.clear_appenders!
      SemanticLogger.default_level = :info
    end

    it "creates an appender when no config is specified" do
      Oxidized.setup_logger
      _(SemanticLogger.default_level).must_equal :info
      _(SemanticLogger.appenders.count).must_equal 1
      _(SemanticLogger.appenders[0]).must_be_instance_of SemanticLogger::Appender::IO
    end

    it "creates an appender when only logger.level is specified" do
      Oxidized.asetus.cfg.logger.level = :debug
      Oxidized.setup_logger

      _(SemanticLogger.default_level).must_equal :debug
      _(SemanticLogger.appenders.count).must_equal 1
    end

    it "creates appenders as specified" do
      Oxidized.asetus.cfg.logger.appenders = [
        { 'type' => 'file', 'file' => '/dev/null' },
        { 'type' => 'stderr', 'level' => :warn },
        { 'type' => 'syslog' }
      ]

      Oxidized.setup_logger

      _(SemanticLogger.appenders.count).must_equal 3
      _(SemanticLogger.appenders[0]).must_be_instance_of SemanticLogger::Appender::File
      # Appender get default level trace, so that they use the default level of SemanticLogger
      _(SemanticLogger.appenders[0].level).must_equal :trace
      _(SemanticLogger.appenders[1]).must_be_instance_of SemanticLogger::Appender::IO
      _(SemanticLogger.appenders[1].level).must_equal :warn
      _(SemanticLogger.appenders[2]).must_be_instance_of SemanticLogger::Appender::Syslog
    end

    it "creates an appender when legacy use_syslog is true" do
      Oxidized.asetus.cfg.use_syslog = true
      Oxidized.setup_logger

      _(SemanticLogger.appenders.count).must_equal 1
      _(SemanticLogger.appenders[0]).must_be_instance_of SemanticLogger::Appender::Syslog
    end

    it "Set loglevel to debug when config.debug is true" do
      _(SemanticLogger.default_level).must_equal :info

      Oxidized.asetus.cfg.debug = true
      Oxidized.setup_logger

      _(SemanticLogger.default_level).must_equal :debug
      _(SemanticLogger.appenders[0]).must_be_instance_of SemanticLogger::Appender::IO

      SemanticLogger.default_level = :info
      Oxidized.asetus.cfg.log = File::NULL
      Oxidized.setup_logger
      _(SemanticLogger.default_level).must_equal :debug
      _(SemanticLogger.appenders[0]).must_be_instance_of SemanticLogger::Appender::File

      SemanticLogger.default_level = :info
      # use_syslog overrides log
      Oxidized.asetus.cfg.use_syslog = true
      Oxidized.setup_logger
      _(SemanticLogger.appenders.count).must_equal 1
      _(SemanticLogger.default_level).must_equal :debug
      _(SemanticLogger.appenders[0]).must_be_instance_of SemanticLogger::Appender::Syslog
    end

    it "keeps specified :trace when debug = true" do
      Oxidized.asetus.cfg.logger.level = :trace
      Oxidized.asetus.cfg.debug = true
      Oxidized.setup_logger

      _(SemanticLogger.default_level).must_equal :trace
    end
  end
  describe '#setup_appender' do
    before(:each) do
      # Reset SemanticLogger settings changed by other tests
      SemanticLogger.clear_appenders!

      Asetus.any_instance.expects(:load)
      Asetus.any_instance.expects(:create).returns(false)
      # Set :home_dir to make sure the OXIDIZED_HOME environment variable is not used
      Oxidized::Config.load({ home_dir: '/cfg_path/' })
    end
    after(:each) do
      SemanticLogger.clear_appenders!
    end

    it "raises an InvalidConfig when the appender type is unknown" do
      err = _{ Oxidized.setup_appender('type' => 'invalid') }.must_raise Oxidized::InvalidConfig
      _(err.message).must_equal 'Unknown logger invalid, edit /cfg_path/config'
    end
  end
end
