module Stackit

  class ParameterResolver

    attr_accessor :stacks

    def initialize(stacks)
      self.stacks = stacks.is_a?(Array) ? stacks : [stacks]
    end

    def resolve(parameter)
      if parameter.is_a?(Array)
      	resolve_parameters(parameter)
      else
      	resolve_parameter(parameter)
      end
    end

  private

    def resolve_parameter(key)
      stacks.each do |_stack|
        value = _stack[key.to_s]
        return value unless value.nil?
      end
      nil
    end

    def resolve_parameters(keys)
      values = []
      stacks.each do |s|
        keys.each do |key|
          value = s[key.to_s]
          values << value unless value.nil?
        end
      end
      values.join(',')
    end

  end

end
