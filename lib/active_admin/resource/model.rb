module ActiveAdmin
  class Model
    def initialize(resource, record)
      @record = record

      if resource
        @record.extend Module.new {
          define_method :model_name do
            resource.resource_name
          end
        }
      end
    end

    def to_model
      @record
    end
  end
end
