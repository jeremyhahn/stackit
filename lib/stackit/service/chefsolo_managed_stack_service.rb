require 'stackit/mixin/vpc'
require 'stackit/mixin/tier'
require 'stackit/mixin/ssh'
require 'stackit/mixin/dns'
require 'stackit/mixin/ami'
require 'stackit/mixin/packer'

module Stackit
  class ChefSoloManagedStackService < Stackit::ManagedStackService

    attr_accessor :config
    attr_accessor :chef_config

    include Stackit::Wait
    include Stackit::Mixin::Vpc
    include Stackit::Mixin::Tier
    include Stackit::Mixin::Ssh
    include Stackit::Mixin::Dns
    include Stackit::Mixin::Ami
    include Stackit::Mixin::Packer

    def initialize(options)
      super(options)
      self.config = Stackit.configuration
      self.chef_config = config[Stackit.environment][:chefsolo]
      self.az_syms = environment_config[:availability_zones]
      self.tier_map = environment_config[:tiers]
      self.tier = default_public_tier
    end

    def stack_name
      options[:stack_name] || "#{Stackit.environment}-#{stack_type}"
    end

    def template
      options[:template] || "#{stack_path}/#{stack_type}.json"
    end

    def chef_cookbooks_artifact
      options[:chef_cookbooks_artifact] || "https://s3.amazonaws.com/#{devops_bucket.bucket_name}/#{chef_cookbooks_artifact_name}"
    end

    def chef_cookbooks_artifact_name
      options[:cookbooks_artifact_name] || chef_config[:cookbooks_archive_name] || 'cookbooks.tar.gz'
    end

    def chef_version
      options[:chef_version] || chef_config[:default_version] || "12.10"
    end

    def chef_runlist
      (options[:chef_runlist] && options[:chef_runlist].length > 0) ? options[:chef_runlist] : ["recipe[#{stack_type}]"]
    end

    def chef_attributes
      options[:chef_attributes] || {}
    end

    def artifacts
      []
    end

  protected

    def chef_cloudformation_params
      {
        "ChefVersion": chef_version,
        "ChefAttributes": build_attributes(chef_attributes),
        "ChefCookbookSource": chef_cookbooks_artifact
      }
    end

    def packer_vars
      {
        instance_type: instance_type,
        security_group_ids: resolve_parameter(environment_config[:default_security_group_key]),
        subnet_id: resolve_parameter(environment_config[:default_public_subnet_key]),
        source_ami: environment_config[:default_ami_id],
        ssh_username: ssh_username,
        ssh_keypair_name: ssh_keypair,
        ssh_private_key_file: ssh_private_key,
        stack: stack_type,
        chef_cookbooks: options[:chef_cookbooks] || environment_config[:packer][:cookbooks_path],
        chef_run_list: chef_runlist.join(','),
        chef_attributes_file: options[:chef_attributes_file] || "/tmp/#{stack_name}-attributes.json"
      }
    end

    def chef_run(runlist)
      attribs = JSON.parse(chef_attributes)
      attribs.merge!(:run_list => runlist) if runlist
      Stackit.logger.debug "Running chef runlist #{attribs[:run_list]} on #{hostname} (#{instance_private_ip})"
      ssh_sudo_exec("root", "chef-solo -c /etc/chef/solo.rb -j /etc/chef/node.json > /var/log/chef-solo.log")
    end

    def chef_update_cookbooks_and_run
      Stackit.logger.debug "Updating cookbooks and running chef on #{hostname} (#{instance_private_ip})"
      ssh_exec("/etc/chef/update-cookbooks-and-run.sh")
    end

  private

    def default_public_tier
      @default_public_tier ||= options[:tier] || environment_config[:default_public_tier]
    end

    def default_chef_attributes
      {
        :set_fqdn => "*.#{dns_private_hosted_zone}"
      }
    end

    def build_attributes(attribs = {})
      attrs = default_chef_attributes.merge(attribs).merge(:run_list => chef_runlist)
      Stackit.debug ? JSON.pretty_generate(attrs) : attrs.to_json
    end

  end
end
