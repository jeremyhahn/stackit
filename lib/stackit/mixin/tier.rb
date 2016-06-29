require_relative 'availability_zone'

module Stackit::Mixin::Tier

  include Stackit::Mixin::AvailabilityZone

  attr_accessor :tier
  attr_accessor :tier_map

  def tier=(tier)
    @tier = tier.to_sym
  end

  def tier_map=(map)
    @tier_map = map
  end

  def subnet
    resolve_parameter(tier_map[tier][az])
  end

  def subnets
    resolve_parameters(tier_map[tier].values)
  end

  def selected_subnet_sym
    tier_map[tier][selected_az_sym]
  end

  def selected_subnet
    resolve_parameter(selected_subnet_sym)
  end

  def random_subnet
    random_az_and_subnet[:subnet]
  end

  def random_subnet_sym
    random_az = random_az_hash
    random_az_sym = random_az.keys[0]
    tier_map[tier][random_az_sym]
  end

  def random_az_and_subnet
    random_az = random_az_hash
    random_az_sym = random_az.keys[0]
    random_az_value = random_az.values[0]
    selected_subnet_sym = tier_map[tier][random_az_sym]
    resolved_subnet = resolve_parameter(selected_subnet_sym)
    {
      :az => random_az_value,
      :subnet => resolved_subnet
    }
  end

end

