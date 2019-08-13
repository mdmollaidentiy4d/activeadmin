require "active_admin/resource"
require "active_admin/resource/model"

module ActiveAdmin
  class ResourceController < BaseController
    module PolymorphicRoutes
      extend ActiveSupport::Concern

      def polymorphic_url(record_or_hash_or_array, options = {})
        super(map_named_resources_for(record_or_hash_or_array), options)
      end

      def polymorphic_path(record_or_hash_or_array, options = {})
        super(map_named_resources_for(record_or_hash_or_array), options)
      end

      private

      def map_named_resources_for(record_or_hash_or_array)
        return record_or_hash_or_array unless record_or_hash_or_array.is_a?(Array)

        record_or_hash_or_array.map { |record| to_named_resource(record) }
      end

      def to_named_resource(record)
        return record unless record.respond_to?(:to_model)

        klass = record.to_model

        resource = nil

        ActiveAdmin.application.namespaces.each do |ns|
          found = ns.resources.values.find do |res|
            res.is_a?(ActiveAdmin::Resource) && res.resource_class == klass.class
          end
          resource = found if found
        end

        ActiveAdmin::Model.new(resource, record)
      end
    end
  end
end
