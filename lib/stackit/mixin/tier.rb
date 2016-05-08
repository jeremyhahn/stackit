require_relative 'availability_zone'

module Stackit::Mixin::Tier

  include Stackit::Mixin::AvailabilityZone

  attr_accessor :tier

  def tier=(tier)
    @tier = tier.to_sym
  end

  def random_tier_az
    random_az ||= random_az_as_hash
  end

  def random_tier_az_sym
    random_tier_az.keys[0].to_sym
  end

  def random_tier_az_value
   random_tier_az.values[0]
  end

  def random_az_and_subnet
    random_az = random_az_as_hash
    random_az_sym = random_az.keys[0].to_sym
    random_az_value = random_az.values[0]
    az_subnet_mapping = az_subnet_map(tier)
    selected_subnet_key = az_subnet_mapping[random_az_sym]
    resolved_subnet = resolve_parameter(selected_subnet_key)
    {
      :az => random_az_value,
      :subnet => resolved_subnet
    }
  end

end

