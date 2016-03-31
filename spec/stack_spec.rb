require 'spec_helper'

module Stackit
  describe Stack do

    include_context 'Stubbed Responses'

    it 'Gets resources, outputs and parameters for a given stack' do

      stub_describe_stacks
      stub_list_stack_resources

      stack = Stack.new({
        cloudformation: cloudformation,
        stack_name: base_stack_name
      })

      expect(stack.parameters.length).to eq 2
      expect(stack.outputs.length).to eq 2
      expect(stack.resources.length).to eq 1
    end

    it 'Hydrates stacks' do

      stub_describe_stacks
      stub_list_stack_resources

      stack = Stack.new({
        cloudformation: cloudformation,
        stack_name: base_stack_name
      }).hydrate!

      expect(stack.stack_id).to eq('arn:aws:cloudformation:us-east-1:123456789012:stack/rspec-stack/1234567890ab-a1b2-c3d4-e5f6-1234567890ab')
      expect(stack.stack_name).to eq('base-stack')
      expect(stack.stack_status).to eq('CREATE_COMPLETE')
    end

  end
end
