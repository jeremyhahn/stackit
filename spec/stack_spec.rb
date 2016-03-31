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


    it 'Gets notification_arns and tags' do

      stub_describe_stacks
      stub_list_stack_resources

      stack = Stack.new({
        cloudformation: cloudformation,
        stack_name: base_stack_name
      })

      expect(stack.tags.length).to eq 2
      expect(stack.notification_arns.length).to eq 2
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

    it 'Transforms parameter hash to AWS ParameterType structure' do

      stack = Stack.new({
        cloudformation: cloudformation,
        stack_name: base_stack_name
      })

      params = stack.send('to_request_parameters', {
        :param0 => 'value1',
        :param1 => 'value2'
      })

      expect(params).to be_an_instance_of Array 
      expect(params[0]).to be_an_instance_of Hash

      expect(params[0]["parameter_key"]).to eq :param0
      expect(params[0]["parameter_value"]).to eq 'value1'

      expect(params[1]["parameter_key"]).to eq :param1
      expect(params[1]["parameter_value"]).to eq 'value2'
    end

    it 'Transforms tag hash to AWS Tag structure' do

      stack = Stack.new({
        cloudformation: cloudformation,
        stack_name: base_stack_name
      })

      params = stack.send('to_request_tags', {
        :param0 => 'value1',
        :param1 => 'value2'
      })

      expect(params).to be_an_instance_of Array 
      expect(params[0]).to be_an_instance_of Hash

      expect(params[0]["key"]).to eq :param0
      expect(params[0]["value"]).to eq 'value1'

      expect(params[1]["key"]).to eq :param1
      expect(params[1]["value"]).to eq 'value2'
    end

  end
end
