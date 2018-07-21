# frozen_string_literal: true

require 'active_support'
require 'active_support/inflector'
require 'will_paginate/array'

module Ditty
  module Helpers
    module Component
      include ActiveSupport::Inflector

      def dataset
        search(filtered(policy_scope(settings.model_class)))
      end

      def list
        count = params['count'] || 10
        page = params['page'] || 1

        ds = dataset.respond_to?(:dataset) ? dataset.dataset : dataset
        return ds if count == 'all'
        # Account for difference between sequel paginate and will paginate
        ds.is_a?(Array) ? ds.paginate(page: page.to_i, per_page: count.to_i) : ds.paginate(page.to_i, count.to_i)
      end

      def heading(action = nil)
        @headings ||= begin
          heading = settings.model_class.to_s.demodulize.titleize
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

      def filters
        self.class.const_defined?('FILTERS') ? self.class::FILTERS : []
      end

      def searchable_fields
        self.class.const_defined?('SEARCHABLE') ? self.class::SEARCHABLE : []
      end

      def filtered(dataset)
        filters.each do |filter|
          next if [nil, ''].include? params[filter[:name].to_s]
          filter[:field] ||= filter[:name]
          filter[:modifier] ||= :to_s
          dataset = apply_filter(dataset, filter)
        end
        dataset
      end

      def apply_filter(dataset, filter)
        value = params[filter[:name].to_s].send(filter[:modifier])
        return dataset.where(filter[:field] => value) unless filter[:field].to_s.include? '.'

        dataset.where(filter_field(filter) => filter_value(filter))
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
        searchable_fields.map { |f| Sequel.ilike(f.to_sym, "%#{params[:q]}%") }
      end

      def search(dataset)
        return dataset if ['', nil].include?(params['q']) || search_filters == []
        dataset.where Sequel.|(*search_filters)
      end
    end
  end
end
