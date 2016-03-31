require 'spec_helper'

describe Stackit do

  it 'has a version number' do
    expect(Stackit::VERSION).not_to be nil
  end

  it 'Stackit.aws can use awsclient services' do
    expect(Stackit.aws.cloudformation).to be_an_instance_of Aws::CloudFormation::Client
    expect(Stackit.aws.ec2).to be_an_instance_of Aws::EC2::Client
  end

  it 'Stackit.cloudformation is an instance of Aws::CloudFormation::Client' do
    expect(Stackit.cloudformation).to be_an_instance_of Aws::CloudFormation::Client
  end

  it 'Stackit.logger is an instance of Logger' do
    expect(Stackit.logger).to be_an_instance_of Logger
  end

end
