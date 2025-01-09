require_relative 'model_helper'

describe 'ATOMS tests' do
  ATOMS.all.each do |test|
    before { init_model_helper }

    case test.type
    when 'output'
      it "#{test} has expected output" do
        skip("check simulation+output data file for #{test}") if test.skip?
        cfg = MockSsh.get_result(self, test).to_cfg
        _(cfg).must_equal test.output
      end

    when 'prompt'
      it "#{test} has working prompt detection" do
        skip("check prompt data file for #{test}") if test.skip?
        @node = MockSsh.get_node(test.model)
        class_sym = Object.constants.find { |const| const.to_s.casecmp(test.model).zero? }
        prompt_re = Object.const_get(class_sym).prompt
        test.pass.each do |want_pass|
          _(want_pass).must_match prompt_re
        end
        test.fail.each do |want_fail|
          _(want_fail).wont_match prompt_re
        end
        test.pass_with_expect.each do |want_pass_with_expect|
          prompt = @node.model.expects want_pass_with_expect
          _(prompt).must_match prompt_re
        end
      end

    when 'secret'
      it "#{test} correctly manages secrets" do
        skip("check secret data file for #{test}") if test.skip?
        Oxidized.config.vars.remove_secret = true
        cfg = MockSsh.get_result(self, test.output_test).to_cfg
        test.pass.each do |want_pass|
          _(cfg).must_match Regexp.new(want_pass)
        end
        test.fail.each do |want_fail|
          _(cfg).wont_match Regexp.new(want_fail)
        end
      end
    end
  end
end
