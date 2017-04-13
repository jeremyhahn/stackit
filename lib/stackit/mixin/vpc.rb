module Stackit::Mixin::Vpc

  def vpc_name
    "#{Stackit.configuration[:global][:vpc][:name]}-#{Stackit.environment}"
  end

end
