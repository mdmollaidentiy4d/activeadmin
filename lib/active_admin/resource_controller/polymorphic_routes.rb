# If we rename a resource by calling `ActiveAdmin.register Model, as: RenamedModel`,
# ActiveAdmin creates a #admin_renamed_model_path helper method.
# If we also use belongs_to inside the ActiveAdmin.register block,
# InheritedResources will call the #polymorphic_path method
# and pass "resource_class.new" as an argument.
# #resource_class is the original model class, and it doesn't know
# anything about the renamed ActiveAdmin resource.
# So when #polymorphic_path calls #model_name on the class, it returns
# the original model name (e.g. "Model", instead of "RenamedModel")
# and will end up calling #admin_model_path, instead of #admin_renamed_model_path.
# This causes an error, because #admin_model_path is not defined.
#
# This issue was solved by customizing the polymorphic routes code for Active Admin.
# We use a custom ActiveAdminHelperMethodBuilder class that is aware of
# #resource_name and #resource_class, and selects the correct model_name
# to handle any renamed resources.
#
# The original PolymorphicRoutes code can be found in:
# actionpack-5.2.1/lib/action_dispatch/routing/polymorphic_routes.rb

module ActiveAdmin
  class ResourceController < BaseController
    module PolymorphicRoutes
      extend ActiveSupport::Concern

      def polymorphic_url(record_or_hash_or_array, options = {})
        opts   = options.dup
        action = opts.delete :action
        type   = opts.delete(:routing_type) || :url

        ActiveAdminHelperMethodBuilder.polymorphic_method self,
                                                          record_or_hash_or_array,
                                                          action,
                                                          type,
                                                          opts
      end

      # Returns the path component of a URL for the given record. It uses
      # <tt>polymorphic_url</tt> with <tt>routing_type: :path</tt>.
      def polymorphic_path(record_or_hash_or_array, options = {})
        opts   = options.dup
        action = opts.delete :action
        type   = :path

        ActiveAdminHelperMethodBuilder.polymorphic_method self,
                                                          record_or_hash_or_array,
                                                          action,
                                                          type,
                                                          opts
      end

      private

      class ActiveAdminHelperMethodBuilder # :nodoc:
        CACHE = { "path" => {}, "url" => {} }

        def self.get(action, type)
          type = type.to_s
          CACHE[type].fetch(action) { build action, type }
        end

        def self.url;  CACHE["url".freeze][nil]; end
        def self.path; CACHE["path".freeze][nil]; end

        def self.build(action, type)
          prefix = action ? "#{action}_" : ""
          suffix = type
          if action.to_s == "new"
            ActiveAdminHelperMethodBuilder.singular prefix, suffix
          else
            ActiveAdminHelperMethodBuilder.plural prefix, suffix
          end
        end

        def self.singular(prefix, suffix)
          new(->(name) { name.singular_route_key }, prefix, suffix)
        end

        def self.plural(prefix, suffix)
          new(->(name) { name.route_key }, prefix, suffix)
        end

        def self.polymorphic_method(recipient, record_or_hash_or_array, action, type, options)
          builder = get action, type

          record_or_hash_or_array = record_or_hash_or_array.compact
          method, args = builder.handle_list(record_or_hash_or_array)

          recipient.send(method, *args)
        end

        attr_reader :suffix, :prefix

        def initialize(key_strategy, prefix, suffix)
          @key_strategy = key_strategy
          @prefix       = prefix
          @suffix       = suffix
        end

        def handle_list(list)
          record_list = list.dup
          record      = record_list.pop

          args = []

          route = record_list.map { |parent| parent.to_s }

          route << begin
            model = record.to_model
            model_name = get_resource_name(model)
            if model.persisted?
              args << model
              model_name.singular_route_key
            else
              @key_strategy.call model_name
            end
          end

          route << suffix

          named_route = prefix + route.join("_")
          [named_route, args]
        end

        private

        def get_resource_name(klass)
          ActiveAdmin.application.namespaces.each do |ns|
            found = ns.resources.values.find do |res|
              res.is_a?(ActiveAdmin::Resource) && res.resource_class == klass.class
            end
            return found.resource_name if found
          end
        end

        [nil, "new", "edit"].each do |action|
          CACHE["url"][action]  = build action, "url"
          CACHE["path"][action] = build action, "path"
        end
      end
    end
  end
end
