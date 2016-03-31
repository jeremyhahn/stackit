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
      expect(stack.parameters[:CommonParam]).to eq('common param value in the base-stack stack')
    end

    it 'Merges parameters from dependent stacks' do

      stub_describe_stacks
      stub_validate_base_template

      base_stack = ManagedStack.new({
        cloudformation: cloudformation,
        stack_name: base_stack_name,
        template: fake_template      
      })

      stub_validate_new_template
      new_stack = ManagedStack.new({
        cloudformation: cloudformation,
        stack_name: base_stack_name,
        template: real_template,
        depends: [base_stack_name]
      })

      merged_params = new_stack.send('merged_parameters')
      expect(merged_params[:CommonParam]).to eq('common param value in the base-stack stack') 
    end

    it 'Merges file parameters' do
      base_stack = ManagedStack.new({
        cloudformation: cloudformation,
        stack_name: base_stack_name,
        template: real_template,
        parameters_file: real_parameters_file,
      })
      merged_params = base_stack.send('merged_parameters')
      expect(merged_params[:VpcName]).to eq('StackIT')
    end

    it 'Merges user defined parameters' do

      stub_describe_stacks
      stub_validate_base_template

      base_stack = ManagedStack.new({
        cloudformation: cloudformation,
        stack_name: base_stack_name,
        template: real_template,
        user_defined_parameters: {
          :TestParam => 'TestValue',
          :CommonParam => 'value from user defined parameters'
        }
      })

      merged_params = base_stack.send('merged_parameters')
      expect(merged_params[:TestParam]).to eq('TestValue') 
      expect(merged_params[:CommonParam]).to eq('value from user defined parameters') 
    end

    it 'Knows whether or not a template needs CAPABILITY_IAM' do
      stack = ManagedStack.new({
        cloudformation: cloudformation,
        stack_name: base_stack_name,
        template: real_template 
      })
      capabilities = stack.send('capabilities')
      expect(capabilities).to be_an_instance_of Array
      expect(capabilities[0]).to eq('CAPABILITY_IAM')
    end

    it 'Creates templates using an explicit path' do
      stack = ManagedStack.new({
        cloudformation: cloudformation,
        stack_name: base_stack_name,
        template: real_template 
      })
      expect(stack.template.options[:template_body] =~ /StackIT VPC/).to eq(67)
    end

    it 'Parses file parameters' do
      stack = ManagedStack.new({
        cloudformation: cloudformation,
        stack_name: base_stack_name,
        template: real_template,
        parameters_file: real_parameters_file
      })
      expect(stack.file_parameters).to be_an_instance_of Hash
      expect(stack.file_parameters[:VpcName]).to eq('StackIT')
    end

    it 'Maps keys defined in the parameter_map' do

      base_stack = ManagedStack.new({
        cloudformation: cloudformation,
        stack_name: base_stack_name,
        template: fake_template,
        parameter_map: {
          :LocalParam => :ToParam 
        }
      })

      key1 = base_stack.send('mapped_key', :key1)
      local_param = base_stack.send('mapped_key', :LocalParam)

      expect(key1).to eq(:key1)
      expect(local_param).to eq(:ToParam)
    end

  end
end
