require_relative "model_helper"
require "json"
require "net/ssh"

describe "Model SRLinux" do
  using Refinements

  before do
    init_model_helper
  end

  %w[23.10.5 26.3.1].product(%w[flat json both]).each do |version, format|
    it "collects #{format} configuration over interactive SSH on #{version}" do
      simulation = YAML.load_file("spec/model/data/srlinux#ixr-d2l_#{version}_interactive#custom_simulation.yaml")
      Net::SSH.stubs(:start).returns MockSsh.new(simulation)
      node = Oxidized::Node.new(name: "example.com", input: "ssh", model: "srlinux",
                                vars: { "ssh_no_exec" => true, "srlinux_config_format" => format })

      status, result = node.run

      _(status).must_equal :success
      _(result.to_cfg).wont_match(/A:(?:admin@)?srl-(?:old|new)#/)
      _(result.to_cfg).wont_include "--{ running }--"
      _(result.to_cfg).wont_include "\e"
      _(result.to_cfg).wont_include "Free Memory"
      if format == "json"
        json = result.to_cfg.split(/^# /, 2).first
        _(JSON.parse(json)).must_be_kind_of Hash
      else
        _(result.to_cfg).must_include "set / acl"
        command = simulation.fetch("commands").fetch("info flat\n")
        lines = MockSsh.new(simulation).interpolate_yaml(command).delete("\r").lines
        config_lines = lines.select { |line| line.start_with?("set / ") }
        _(result.to_cfg).must_include config_lines.first
        _(result.to_cfg).must_include config_lines.last
      end
      _(JSON.parse(result.type_to_str("srlinux-json"))).must_be_kind_of Hash if format == "both"
    end
  end

  %w[23.10.5 26.3.1].each do |version|
    [nil, "flat", "json", "both"].each do |format|
      it "collects #{format || 'default'} configuration on #{version}" do
        simulation = YAML.load_file("spec/model/data/srlinux#ixr-d2l_#{version}#simulation.yaml")
        ssh = MockSsh.new(simulation)
        commands = []
        original_exec = ssh.method(:exec!)
        ssh.define_singleton_method(:exec!) do |command|
          commands << command
          original_exec.call(command)
        end
        Net::SSH.stubs(:start).returns ssh
        node = Oxidized::Node.new(name: "example.com", input: "ssh", model: "srlinux",
                                  vars: { "srlinux_config_format" => format })

        status, result = node.run

        _(status).must_equal :success
        _(commands.include?("info flat")).must_equal [nil, "flat", "both"].include?(format)
        _(commands.include?("info | as json")).must_equal %w[json both].include?(format)
        _(result.to_cfg).wont_include "Free Memory"
        if format == "json"
          expected = ssh.interpolate_yaml(simulation.fetch("commands").fetch("info | as json\n"))
          json = result.to_cfg[0, expected.length]
          _(json).must_equal expected
          _(JSON.parse(json)).must_be_kind_of Hash
        else
          expected = ssh.interpolate_yaml(simulation.fetch("commands").fetch("info flat\n"))
          _(result.to_cfg).must_include expected
        end
        if format == "both"
          json = result.type_to_str("srlinux-json")
          _(JSON.parse(json)).must_be_kind_of Hash
          _(result.type("srlinux-json").first.name).must_equal "json"
        else
          _(result.types).must_be_empty
        end
      end
    end
  end
end
