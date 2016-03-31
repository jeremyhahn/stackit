require 'spec_helper'

module Stackit
  describe ManagedStack do

    include_context 'Stubbed Responses'

    it 'Validates cloudformation templates and returns a hash of parameters defined in the template' do

      stub_describe_stacks
      stub_validate_base_template

      stack = ManagedStack.new({
      	cloudformation: cloudformation,
      	stack_name: base_stack_name,
        template: fake_template 
      })

      allow(stack).to receive(:create!).and_return(nil)
      stack.create!

      expect(stack.parameters).to be_an_instance_of Hash
      expect(stack.parameters.length).to eq 2
      expect(stack.parameters['CommonParam']).to eq('common param value in the base-stack stack')
    end

  end
end
