require "active_admin/resource"
require "active_admin/resource/model"

module ActiveAdmin
  class ResourceController < BaseController
    module PolymorphicRoutes
      def polymorphic_url(record_or_hash_or_array, options = {})
        super(map_named_resources_for(record_or_hash_or_array), options)
      end

      def polymorphic_path(record_or_hash_or_array, options = {})
        super(map_named_resources_for(record_or_hash_or_array), options)
      end

      private

      def map_named_resources_for(record_or_hash_or_array)
        return record_or_hash_or_array unless record_or_hash_or_array.is_a?(Array)

        namespace_name = record_or_hash_or_array.first.is_a?(String) ? record_or_hash_or_array.first : :root

        record_or_hash_or_array.map { |record| to_named_resource(namespace_name, record) }
      end

      def to_named_resource(namespace_name, record)
        return record unless record.respond_to?(:to_model)

        klass = record.to_model

        namespace = ActiveAdmin.application.namespace(namespace_name.to_sym)

        resource = namespace.resources[klass.class]

        ActiveAdmin::Model.new(resource, record)
      end
    end
  end
end
