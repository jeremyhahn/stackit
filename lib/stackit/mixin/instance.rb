module Stackit::Mixin::Instance

  def instance_private_ip
    Stackit.aws.ec2.describe_instances(
      instance_ids: [instance_id]
    )[:reservations][0][:instances][0][:private_ip_address]
  end

  def instance_id(key = :Instance)
    stack[key.to_sym]
  end

  def instance_type
    @instance_type ||= options[:instance_type] ||
     environment_config[:default_instance_type] || 
     "t2.micro"
  end

end
