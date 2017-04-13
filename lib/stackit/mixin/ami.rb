module Stackit::Mixin::Ami

  def ami(tag = environment_config[:default_ami_tag_name], value = stack_type)
    default_ami_id = environment_config[:default_ami_id]
    return default_ami_id unless stack_type
    images = Stackit.aws.ec2.describe_images({
      filters:[{
        name: "tag:#{tag}",
        values: [value]
      }]
    }).images.sort_by { |image| 
      image[:creation_date]
    }
    images.length == 0 ? default_ami_id : images.last.image_id
  end

end