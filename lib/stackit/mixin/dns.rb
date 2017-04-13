module Stackit::Mixin::Dns

  def dns_public_hosted_zone
    @public_hosted_zone ||= resolve_parameter(environment_config[:public_hosted_zone_key])
  end

  def dns_private_hosted_zone
    @private_hosted_zone ||= resolve_parameter(environment_config[:private_hosted_zone_key])
  end

end
