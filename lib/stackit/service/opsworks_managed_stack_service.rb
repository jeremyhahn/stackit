require 'stackit/mixin/opsworks'

module Stackit

  class OpsWorksManagedStackService < ManagedStackService
    
    include Stackit::Wait

    attr_accessor :opsworks
    attr_accessor :config

    def initialize(options)
      super(options)
      self.opsworks = options[:opsworks] || Stackit.aws.opsworks
      self.environment_config = Laws.configuration[Laws.environment]
      self.opsworks_config = Laws.configuration[:opsworks]
    end

    def opsworks_service_role_arn(key = opsworks_service_role_key)
      "arn:aws:iam::#{Stackit.aws.account_id}:role/#{resolve_parameter(key)}"
    end

    def opsworks_cookbook_source(opsworks_bucket_key = opsworks_cookbook_source_key, opsworks_cookbook_archive)
      "https://s3.amazonaws.com/#{resolve_parameter(opsworks_bucket_key)}/#{opsworks_cookbook_archive}"
    end

    def opsworks_stack_id(key = opsworks_stack_key)
      Stackit::ParameterResolver.new(stack).resolve(key)
    end

    def opsworks_layer_id(key = opsworks_layer_key)
      Stackit::ParameterResolver.new(stack).resolve(key)
    end

    def opsworks_layers(stack_id)
      opsworks.describe_layers(
        stack_id: stack_id
      ).layers
    end

    def opsworks_instance(key = opsworks_instance_key)
      opsworks.describe_instances({
        instance_ids: [
          Stackit::ParameterResolver.new(stack).resolve(key)
        ]
      })[:instances][0]
    end

    def opsworks_update_custom_cookbooks(stack_id, layer_id)
      opsworks.create_deployment({
        stack_id: stack_id,
        layer_ids: [layer_id],
        command: {
          name: "update_custom_cookbooks"
        }
      })[:deployment_id]
    end

    def opsworks_execute_recipe(stack_id, layer_ids, recipes, attributes = nil)
  	  recipes = recipes.is_a?(Array) ? recipes : [recipes]
  	  layer_ids = layer_ids.is_a?(Array) ? layer_ids : [layer_ids]
      opsworks.create_deployment({
        stack_id: stack_id,
          layer_ids: layer_ids,
          command: {
            name: "execute_recipes",
            args: {
              "recipes" => recipes,
            },
          },
          custom_json: attributes
        })[:deployment_id]
    end

    def opsworks_wait_for_deployment(deployment_id, status_pattern = /successful/)
      Stackit.logger.info "Waiting for deployment #{deployment_id} to complete..."
      wait_for(timeout: 15.minutes) do
        deployment = Stackit.aws.opsworks.describe_deployments({
          deployment_ids: [deployment_id]
        })[:deployments][0]
        case deployment.status
        when /failed/
          raise Stackit::WaitError, "Deployment failed during wait: #{deployment_id}"
        when status_pattern
          yield stack if block_given?
          true
        else
          false
        end
      end
    end

  protected

    def opsworks_service_role_key
      opsworks_config[:service_role_arn_key] || :OpsWorksServiceRole
    end

    def opsworks_bucket_key
       environment_config[:devops_bucket_name] || :DevOpsBucket
    end


    def opsworks_cookbook_source(bucket_key = opsworks_bucket_key, opsworks_cookbook_archive)
      "https://s3.amazonaws.com/#{resolve_parameter(bucket_key)}/#{opsworks_cookbook_archive}"
    end

    cookbook_archive = opsworks_config[:service_role_arn_key] || 'cookbooks.tar.gz'

    def opsworks_stack_key
      opsworks_config[:stack_key] || :OpsWorksStack
    end

    def opsworks_layer_key
      opsworks_config[:layer_key] || :OpsWorksLayer
    end

    def opsworks_instance_key
      opsworks_config[:instance_key] || :OpsWorksInstance
    end

  end
end
