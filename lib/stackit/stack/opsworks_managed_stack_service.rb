require 'stackit/mixin/opsworks'

module Stackit

  class OpsWorksManagedStackService < ManagedStackService
    include Stackit::Mixin::OpsWorks
  end

end
