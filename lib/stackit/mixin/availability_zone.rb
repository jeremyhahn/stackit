module Stackit::Mixin::AvailabilityZone

  attr_accessor :vpc_az_stack_keys

  def vpc_az_stack_keys=(keys)
    @vpc_az_stack_keys = keys.each do { |key|
      key = key.to_sym
    }
  end

  def selected_az_sym
    selected_az.keys[0].to_sym
  end

  def selected_az_value
    selected_az.values[0]
  end

  def subnet_id_for_selected_az(tier, az_sym = selected_az_sym)
    az_subnet_mapping = az_subnet_map(tier)
    selected_subnet_key = az_subnet_mapping[az_sym]
    resolve_parameter(selected_subnet_key)
  end

  def random_az(keys = default_az_keys)
    resolve_parameters(keys).split(',').sample
  end

  def random_az_as_hash
    sampled_az_key = az_keys.sample
    sampled_az_value = resolve_parameter(sampled_az_key.to_sym)
    {
      sampled_az_key => sampled_az_value
    }
  end

 private

  def az_keys
    vpc_az_stack_keys || [:VpcAvailabilityZone1, :VpcAvailabilityZone2, :VpcAvailabilityZone3]
  end

  def selected_az
    @selected_az ||= random_az_as_hash
  end

end

