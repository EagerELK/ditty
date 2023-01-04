# frozen_string_literal: true

require 'active_support'
require 'active_support/inflector'
require 'active_support/core_ext/object/blank'
require 'will_paginate/array'

module Ditty
  module Helpers
    module Component
      include ActiveSupport::Inflector

      # param :count, Integer, min: 1, default: 10 # Can't do this, since count can be `all`
      def check_count
        return 10 if params[:count].nil?

        count = params[:count].to_i
        return count if count >= 1

        excp = Sinatra::Param::InvalidParameterError.new 'Parameter cannot be less than 1'
        excp.param = :count
        raise excp
      end

      def dataset
        ds = policy_scope(settings.model_class)
        ds = ds.where Sequel.|(*search_filters) unless search_filters.blank?
        ds = ds.order ordering unless ordering.blank?
        filtered(ds)
      end

      def list
        param :q, String
        param :page, Integer, min: 1, default: 1
        param :sort, String
        param :order, String, in: %w[asc desc], transform: :downcase
        # TODO: Can we dynamically validate the search / filter fields?

        ds = dataset
        ds = ds.dataset if ds.respond_to?(:dataset)
        params[:order] ||= 'asc' if params[:sort]
        return ds if params[:count] == 'all'

        params[:count] = check_count

        # Account for difference between sequel paginate and will paginate
        return ds.paginate(page: params[:page], per_page: params[:count]) if ds.is_a?(Array)

        ds.paginate(params[:page], params[:count])
      end

      def heading(action = nil)
        @headings ||= begin
          heading = settings.heading || settings.model_class.to_s.demodulize.singularize.titleize
          h = Hash.new(heading)
          h[:new] = "New #{heading}"
          h[:list] = pluralize heading
          h[:edit] = "Edit #{heading}"
          h
        end
        @headings[action]
      end

      def dehumanized
        settings.dehumanized || underscore(heading)
      end

      def filter_fields
        self.class.const_defined?('FILTERS') ? self.class::FILTERS : []
      end

      def searchable_fields
        self.class.const_defined?('SEARCHABLE') ? self.class::SEARCHABLE : []
      end

      def filtered(ds)
        filters.each do |filter|
          ds = apply_filter(ds, filter)
        end
        ds
      end

      def filters
        filter_fields.filter_map do |filter|
          next if params[filter[:name]].blank?

          filter[:field] ||= filter[:name]
          filter[:modifier] ||= :to_s # TODO: Do this with Sinatra Param?
          filter
        end
      end

      def ordering
        return if params[:sort].blank?

        Sequel.send(params[:order].to_sym, params[:sort].to_sym)
      end

      def apply_filter(ds, filter)
        value = params[filter[:name]].send(filter[:modifier])
        return ds.where(filter[:field] => value) unless filter[:field].to_s.include? '.'

        ds.where(filter_field(filter) => filter_value(filter))
      end

      def filter_field(filter)
        filter[:field].to_s.split('.').first.to_sym
      end

      def filter_value(filter)
        field = filter[:field].to_s.split('.').last.to_sym
        assoc = filter_association(filter)
        value = params[filter[:name].to_s].send(filter[:modifier])
        value = assoc.associated_dataset.first(field => value)
        value.nil? ? assoc.associated_class.new : value
      end

      def filter_association(filter)
        assoc = filter[:field].to_s.split('.').first.to_sym
        assoc = settings.model_class.association_reflection(assoc)
        raise "Unknown association #{assoc}" if assoc.nil?

        assoc
      end

      def search_filters
        return [] if params[:q].blank?

        searchable_fields.map { |f| Sequel.ilike(f.to_sym, "%#{params[:q]}%") }
      end
    end
  end
end
