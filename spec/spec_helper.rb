$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'stackit'
require 'pp'

begin
  require 'pry-byebug'
rescue LoadError
end

Stackit.debug = true

RSpec.shared_context 'Stubbed Responses' do

  let(:cloudformation) { Aws::CloudFormation::Client.new(:stub_responses => true) }
  let(:base_stack_name) { 'base-stack' }
  let(:new_stack_name) { 'new-stack' }
  let(:fake_template) { 'fake.json' }

  def stub_describe_stacks(stack_name = base_stack_name)
    cloudformation.stub_responses(:describe_stacks, {
      stacks: [{
        stack_id: 'arn:aws:cloudformation:us-east-1:123456789012:stack/rspec-stack/1234567890ab-a1b2-c3d4-e5f6-1234567890ab',
        stack_name: stack_name,
        creation_time: Time.now.utc,
        stack_status: 'CREATE_COMPLETE',
        parameters: [{
          parameter_key: "ParameterKey1",
          parameter_value: 'value1'
	    }, {
	      parameter_key: 'CommonParam',
	      parameter_value: "common param value in the #{stack_name} stack"
	    }],
	    outputs: [{
	      output_key: 'CommonOutput',
	      output_value: "common output value in the #{stack_name} stack"
	    }, {
	      output_key: "OutputKey2",
	      output_value: 'value2'
	    }]
	  }]
	})
  end

  def stub_list_stack_resources
    cloudformation.stub_responses(:list_stack_resources, {
	  stack_resource_summaries: [{
	    logical_resource_id: 'CommonResource',
	    physical_resource_id: 'rspec-123',
	    resource_status: 'CREATE_COMPLETE',
	    resource_type: 'AWS::EC2::VPCGatewayAttachment',
	    last_updated_timestamp: Time.now
	  }]
	})
  end

  def stub_validate_base_template
  	allow(File).to receive(:open).and_return(File)
  	allow(File).to receive(:read).and_return(nil)
    cloudformation.stub_responses(:validate_template, {
	  parameters: [{
	    parameter_key: 'base-stack-key',
	    default_value: 'value'
	  }, {
	  	parameter_key: 'CommonParam',
	  	default_value: 'common param value in the base-stack template'
	  }]
	})
  end

  def stub_validate_new_template
  	allow(File).to receive(:open).and_return(File)
  	allow(File).to receive(:read).and_return(nil)
    cloudformation.stub_responses(:validate_template, {
	  parameters: [{
	    parameter_key: 'CommonParam',
	    default_value: 'common param in the new template'
	  }, {
	  	parameter_key: 'new-stack-key',
	  	default_value: 'value'
	  }, {
        parameter_key: 'CommonOutput',
	  	default_value: 'value'
	  }, {
        parameter_key: 'CommonResource',
	  	default_value: 'value'
	  }]
	})
  end

end
