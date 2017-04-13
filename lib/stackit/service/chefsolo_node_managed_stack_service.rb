require 'stackit/wait'
require 'stackit/mixin/instance'
require 'stackit/service/chefsolo_managed_stack_service'

module Stackit
  class ChefSoloNodeManagedStackService < Stackit::ChefSoloManagedStackService

    include Stackit::Mixin::Instance

    attr_accessor :image_id
    attr_accessor :node_id

    def initialize(options)
      super(options)
      self.image_id = options[:image_id] || ami
      self.node_id = options[:node_id] || 0
      self.az_id = options[:az] || 1
      self.az = resolve_az(options[:az] || 1)
      self.ssh_username = options[:ssh_username] if options[:ssh_username]
      self.ssh_keypair = options[:ssh_keypair] if options[:ssh_keypair]
      self.ssh_private_key = options[:ssh_private_key] if options[:ssh_private_key]
    end

    def stack_name
      options[:stack_name] || hostname
    end

    def template
      options[:template] || "#{stack_type}/node.json"
    end

    def user_defined_parameters
      {
        :Environment => Stackit.environment,
        :AvailabilityZone => availability_zone,
        :KeyPair => ssh_keypair,
        :Hostname => hostname,
        :Subnet => subnet,
        :ImageId => image_id,
        :InstanceType => instance_type,
        :ElasticIp => true,
        :StackType => stack_type
      }.merge(chef_cloudformation_params)
    end

    def chef_attributes
      super.merge({:set_fqdn => fqdn})
    end

    def hostname_id
      @hostname_id ||= "#{stack_type}#{node_id + 1}"
    end

    def hostname
      @hostname ||= az_id.nil? ? "#{Stackit.environment}-#{stack_type}#{node_id}" :
        "a#{az_id}-#{Stackit.environment}-#{hostname_id}"
    end

    def fqdn
      @fqdn ||= "#{hostname}.#{dns_private_hosted_zone}"
    end

  end
end
