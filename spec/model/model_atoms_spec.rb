require_relative 'model_helper'
require_relative 'atoms'

describe 'ATOMS tests' do
  ATOMS.get.each do |test|
    test_string = "ATOMS/#{test.type} (#{test.model} / #{test.desc})"

    before { init_model_helper }

    if test.type == 'output'
      it "#{test_string} has expected output" do
        skip("check simulation+output data file for #{test_string}") if test.skip?
        cfg = MockSsh.get_result(self, test).to_cfg
        _(cfg).must_match test.output
      end

    elsif test.type == 'prompt'
      it "#{test_string} has working prompt detection" do
        skip("check prompt data file for #{test_string}") if test.skip?
        @node = MockSsh.get_node(test.model)
        class_sym = Object.constants.find { |const| const.to_s.casecmp(test.model).zero? }
        prompt_re = Object.const_get(class_sym).prompt
        test.pass.each do |want_pass|
          _(want_pass).must_match prompt_re
        end
        test.fail.each do |want_fail|
          _(want_fail).wont_match prompt_re
        end
      end
    end
  end
end
