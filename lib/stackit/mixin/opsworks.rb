module Stackit::Mixin::OpsWorks

  def opsworks_service_role_arn(key = :OpsWorksServiceRole)
    "arn:aws:iam::#{Stackit.aws.account_id}:role/#{resolve_parameter(key)}"
  end

  def opsworks_cookbook_source(key = :DevOpsBucket, cookbook_archive = 'cookbooks.tar.gz')
    "https://s3.amazonaws.com/#{resolve_parameter(key)}/#{cookbook_archive}"
  end

end

