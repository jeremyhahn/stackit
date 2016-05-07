module Stackit::Mixin::AvailabilityZone

  def random_az(keys = [:VpcAvailabilityZone1, :VpcAvailabilityZone2, :VpcAvailabilityZone3])
    resolve_parameters(keys).split(',').sample
  end

end
