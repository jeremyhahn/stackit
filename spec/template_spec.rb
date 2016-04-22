require 'spec_helper'

module Stackit
  describe Template do

    include_context 'Stubbed Responses'

    let(:template) { Template.new({
        cloudformation: cloudformation,
        template_path: fake_template
      })
    }

    it 'template_body parses fully qualified file system templates' do
      template = Template.new({
        cloudformation: cloudformation,
        template_path: fake_template
      })
      allow(File).to receive(:read).and_return("rspec template body")
      allow(File).to receive(:exist?).with(fake_template).and_return(true)
      template.parse!
      expect(template.options[:template_body]).to eq('rspec template body')
    end

    it 'template_body parses relative file system templates' do
      template = Template.new({
        cloudformation: cloudformation,
        template_path: "#{Dir.pwd}/#{fake_template}"
      })
      allow(File).to receive(:read).and_return("rspec template body")
      allow(File).to receive(:exist?).with(fake_template).and_return(false)
      allow(File).to receive(:exist?).with("#{Dir.pwd}/#{fake_template}").and_return(true)
      template.parse!
      expect(template.options[:template_body]).to eq('rspec template body')
    end    

    it 'parses remote S3 templates' do
      fake_s3_path = "https://s3.amazonaws.com/fake-bucket/#{fake_template}"
      template = Template.new({
        cloudformation: cloudformation,
        template_path: fake_s3_path
      })
      expect(template).to receive(:body).exactly(0).times
      template.parse!
      expect(template.options[:template_url]).to eq(fake_s3_path) 
    end

    it 'validates cloudformation templates and returns their parameters' do
      stub_validate_base_template
      template = Template.new({
        cloudformation: cloudformation,
        template_path: fake_template
      })
      expect(template).to receive(:body).and_return(nil)
      template.parse!
      expect(template.options[:parameters]).to be_an_instance_of Array
      expect(template.options[:parameters][0]['parameter_key']).to eq('base-stack-key')
      expect(template.options[:parameters][0]['default_value']).to eq('value')
      expect(template.options[:parameters][0]['no_echo']).to eq(nil)
      expect(template.options[:parameters][0]['description']).to eq(nil)
      expect(template.options[:parameters][1]['parameter_key']).to eq('CommonParam')
      expect(template.options[:parameters][1]['default_value']).to eq('common param value in the base-stack template')
      expect(template.options[:parameters][1]['no_echo']).to eq(nil)
      expect(template.options[:parameters][1]['description']).to eq(nil)
    end

    it 'parsed_parameters returns a Hash of parameter_key => default_value' do
      stub_validate_base_template
      template = Template.new({
        cloudformation: cloudformation,
        template_path: fake_template
      })
      expect(template).to receive(:body).and_return(nil)
      template.parse!
      expect(template.parsed_parameters[:CommonParam]).to eq('common param value in the base-stack template') 
    end

    it 'understands when a template DOESNT need CAPABILITY_IAM' do
      template = Template.new({
        cloudformation: cloudformation,
        template_path: fake_template
      })
      allow(File).to receive(:read).and_return("rspec template body")
      allow(File).to receive(:exist?).with(fake_template).and_return(true)
      template.parse!
      expect(template.needs_iam_capability?).to be_falsey
    end    

    it 'understands when a template needs CAPABILITY_IAM' do
      template = Template.new({
        cloudformation: cloudformation,
        template_path: real_template
      })
      template.parse!
      expect(template.needs_iam_capability?).to be_truthy
    end

  end
end
