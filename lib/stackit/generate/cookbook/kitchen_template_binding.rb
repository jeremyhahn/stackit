module Stackit::Generate::Cookbook

  class KitchenTemplateBinding

    attr_accessor :aws_ssh_key
    attr_accessor :security_group
    attr_accessor :region
    attr_accessor :availability_zone
    attr_accessor :subnet_id
    attr_accessor :iam_profile_name
    attr_accessor :instance_type
    attr_accessor :associate_public_ip
    attr_accessor :transport_ssh_key
    attr_accessor :transport_username
    attr_accessor :platform_ami
    attr_accessor :platform_username
    attr_accessor :service_name

    def initialize(options)
      self.aws_ssh_key = options[:aws_ssh_key]
      self.security_group = options[:security_group]
      self.region = options[:region]
      self.availability_zone = options[:availability_zone]
      self.subnet_id = options[:subnet_id]
      self.iam_profile_name = options[:iam_profile_name]
      self.instance_type = options[:instance_type]
      self.associate_public_ip = options[:associate_public_ip]
      self.transport_ssh_key = options[:transport_ssh_key]
      self.transport_username = options[:transport_username]
      self.platform_ami = options[:platform_ami]
      self.platform_username = options[:platform_username]
      self.service_name = options[:service_name]
    end

    def get_binding
      binding()
    end

  end
end

