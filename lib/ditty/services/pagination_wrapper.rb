# frozen_string_literal: true

module Ditty
  module Services
    class PaginationWrapper
      attr_reader :list

      def initialize(list)
        @list = list
      end

      def last_page?
        if list.respond_to? :'last_page?'
          list.last_page?
        else
          list.next_page.nil?
        end
      end

      def first_page?
        if list.respond_to? :'first_page?'
          list.first_page?
        else
          list.previous_page.nil?
        end
      end

      def prev_page
        if list.respond_to? :prev_page
          list.prev_page
        else
          list.previous_page
        end
      end

      def page_count
        if list.respond_to? :page_count
          list.page_count
        else
          list.total_pages
        end
      end

      def page_size
        if list.respond_to? :page_size
          list.page_size
        else
          list.per_page
        end
      end

      def pagination_record_count
        if list.respond_to? :pagination_record_count
          list.pagination_record_count
        else
          list.total_entries
        end
      end

      def method_missing(method, *args)
        return super unless respond_to_missing?(method)

        list.send(method, *args)
      end

      def respond_to_missing?(method, _include_private = false)
        list.respond_to? method
      end

      def current_page_record_range
        if list.respond_to? :current_page_record_range
          list.current_page_record_range
        else
          return (0..0) if list.current_page > page_count

          a = 1 + (list.current_page - 1) * page_size
          b = a + page_size - 1
          b = pagination_record_count if b > pagination_record_count
          a..b
        end
      end
    end
  end
end
