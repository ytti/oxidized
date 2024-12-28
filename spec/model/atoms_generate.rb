require_relative 'model_helper'

# FIXME: refactor result generation/init_model_helper so that we don't need to run it inside test
describe('') do
  it('') do
    ATOMS.get(ATOMS::TestOutput, '*:simulation.yaml').each do |test|
      print "Generating output file for #{test}... "
      begin
        init_model_helper
        test.generate(MockSsh)
        puts "OK"
      rescue ATOMS::TestOutput::OutputGenerationError => e
        puts e.message
      end
    end
  end
end
