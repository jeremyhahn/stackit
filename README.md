# stackit

Simple, elegant CloudFormation dependency management.

[CloudFormation parameters](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html) can become cumbersome to manage as your infrastructure scales. At some point, you realize there has to be a better way than specifying parameters on the command line or putting them into files and shell scripts.

StackIT makes it easier to manage the lifecycle of your stacks by allowing you to map values from existing stacks. For example, we can have a VPC stack that defines networking resources that a separate remote access VPN stack references when launched. StackIT will automatically map VPC resource, output and/or parameter values to parameters defined in the VPN template. 

StackIT can also work with parameter files and user defined parameters in conjunction with CloudFormation stacks. This is quite useful if you want to override parameters.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'stackit'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install stackit

## Parameters

Let's take a look at each of the ways to get parameter values into your template.

StackIT uses the following order of precedence when determining which parameter value to pass into your template.

1. File Parameters
2. Existing CloudFormation Stacks
3. User Defined Parameters

##### File Parameters

File parameters work just like the default AWS CLI parameters file. Simply specify the path to your JSON parameter file using the `--parameter-file` option.

    stackit create-stack --stack-name mystack --template mytemplate.json --parameter-file mytemplate.parameters

##### Existing CloudFormation Stacks

Your stack can `--depends` on existing stacks. Any resource, output, or parameter whose ID matches a parameter key in the template will automatically have it's value passed into the stack during creation/update.

> Parameter values mapped using `--depends` override parameters defined in the parameter file.

    stackit create-stack --stack-name mystack --template my-template --parameter-file mytemplate.parameters --depends myvpc

##### User Defined Parameters

User defined parameters allow you to define the parameters yourself using the `--parameters` option. 

> User defined parameters override both file parameters and `--depends` parameters.

## Usage

### CLI

StackIT ships with [Thor](http://whatisthor.com/) to provide a command line interface to stack management. Run the `help` command for details.

    # show top level commands
    stackit help

    # show options for create-stack command
    stackit help create-stack

###### Create a stack using a parameter file

    stackit create-stack --stack-name mystack --template mytemplate.json --parameter-file mytemplate.parameters

###### Create a stack using `--depends` to reference resource, output and parameter values in the "myvpc" stack

    stackit create-stack --stack-name mystack --template mytemplate.json --depends myvpc

###### Create a stack using user defined parameters

    stackit create-stack --stack-name mystack --template mytemplate.json --parameters param1:value1 param2:value2

###### Create a stack using a parameter file, overriding parameters found in the "myvpc" resource, output or parameters.

    stackit create-stack --stack-name mystack --template mytemplate.json --parameter-file mytemplate.parameters --depends myvpc

###### Create a stack using a parameter file, overriding those parameters with mapped parameters in the "myvpc" stack, and override both of those with user defined parameters.

    stackit create-stack --stack-name mystack --template mytemplate.json --parameter-file mytemplate.parameters --depends myvpc --parameters param1:final_value

##### Mapping Parameters

You may optionally map parameters that don't have matching keys. For example, let's map the value for the "Vpc" resource into the "VpcId" parameter in our VPN stack using the `--parameter-map` option.

    # Maps the "Vpc" resource value in the "myvpc" stack to the "VpcId" parameter in the VPN stack.
    stackit create-stack --stack-name myvpn --template vpn.json --parameter-file vpn.parameters --depends myvpc --parameter-map VpcId:Vpc

### Library

StackIT can be used as a library in your own automation tools.

```ruby
  ManagedStack.new({
    template: '/path/to/template.json',
    stack_name: 'mystack',
    depends: ['otherstack'],
    user_defined_parameters: {
      :param1 => 'myvalue',
      :param2 => 'something else'
    }
  }).create!
```

```ruby
module MyToolkit::MyStack

  class Service < Stackit::OpsWorksManagedStackService

    def initialize(options = {})
      super(options)
    end

    def stack_name
      options[:stack_name] || "#{Stackit.environment}-mystack"
    end

    def template
      options[:template] || "#{Stackit.home}/mytoolkit/mystack/template.json"
    end

    def user_defined_parameters
      {
        :StackEnvironment => Stackit.environment,
        :KeyPair => "#{Stackit.environment}-myapp",
        :OpsWorksStackName => stack_name,
        :OpsWorksServiceRoleArn => opsworks_service_role_arn,
        :UseOpsworksSecurityGroups => "false",
        :OpsWorksDefaultOs => "Amazon Linux 2016.03",
        :OpsWorksDefaultRootDeviceType => 'ebs',
        :OpsWorksConfigureRunlist => "mycookbook::configure",
        :OpsWorksDeployRunlist => "mycookbook::deploy",
        :OpsWorksSetupRunlist => "mycookbook::setup",
        :OpsWorksShutdownRunlist => "mycookbook::shutdown",
        :OpsWorksUndeployRunlist => "mycookbook::undeploy",
        :S3CookbookSource => 'https://s3.amazonaws.com/devops-automation/cookbooks.tar.gz',
        :EbsVolumeType => 'gp2',
        :EbsVolumeSize => 140 # GB
      }
    end

    def opsworks_stack_id
      Stackit::ParameterResolver.new(stack).resolve(:OpsWorksStack)
    end

    def opsworks_layer_id
      Stackit::ParameterResolver.new(stack).resolve(:OpsWorksLayer)
    end

  end
end

service = MyToolkit::MyStack::Service.new
service.create! # creates the stack
service.update! # updates the stack
service.delete! # deletes the stack

```

At this point, you may be interested in my [awskit](https://github.com/jeremyhahn/awskit) project that generates a DevOps toolkit based on stackit.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jeremyhahn/stackit.


## License

The gem is available as open source under the terms of the [GNU GENERAL PUBLIC LICENSE](http://www.gnu.org/licenses/gpl-3.0.en.html).
