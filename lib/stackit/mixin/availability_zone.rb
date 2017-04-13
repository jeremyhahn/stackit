module Stackit::Mixin::AvailabilityZone

  attr_accessor :az
  attr_accessor :az_id
  attr_accessor :az_syms

  def az=(az)
    @az = az.to_sym || az_syms[0]
  end

  def az_syms=(keys)
    @az_syms = keys.each{ |key|
      key = key.to_sym
    }
  end

  def az_hash
    {
      az_sym => resolve_parameter(az_sym)
    }
  end

  def availability_zone
    resolve_parameter(az)
  end

  def availability_zones
    resolve_parameters(az_syms)
  end

  def selected_az_sym
    selected_az_hash.keys[0].to_sym
  end

  def selected_az
    selected_az_hash.values[0]
  end

  def random_az
    resolve_parameters(az_syms).split(',').sample
  end

  def random_az_hash
    sampled_az_sym = az_syms.sample 
    {
      sampled_az_sym => resolve_parameter(sampled_az_sym)
    }
  end

  def resolve_az(index)
    raise "index must be an integer. Got #{index.class} :#{index}" unless index.is_a?(Integer)
    az_syms[index-1]
  end

 private

  def selected_az_hash
    @selected_az_hash ||= random_az_hash
  end

end

