# frozen_string_literal: true

require 'syto/version'

# Syto
module Syto
  class Error < StandardError; end

  def self.included(base)
    base.extend(ClassMethods)
  end

  # Class methods for Syto
  module ClassMethods
    # Define class with custom filter implementation
    #
    # $ cat app/model/user.rb
    # class User < ActiveModel
    #   include Syto
    #   syto_attrs_map :role_id, :country, rate: { key_from: rate_from, key_to: rate_to }
    # end

    # $ cat app/models/post.rb
    # class Post < ActiveModel
    #   include Syto
    #   syto_filters_class PostFilter
    # end
    #
    # $ cat app/models/concerns/post_filter.rb
    # class PostFilter < Syto
    #   def define_filters
    #     self.result = result.where(published: params[:published])
    #   end
    # end
    #
    # Usage:
    #
    # params = { country: 'UA', rate_from: 2 }
    # User.filter_by(params)
    #
    # params = { published: true }
    # Post.syto(params)
    #

    # Set class with customized filter settings
    #
    # @param [Class] filter_klass
    #
    def syto_filters_class(filter_klass)
      @filter_klass = filter_klass
    end

    # Define map of filterable attributes
    #
    # @param [Array] attrs_map
    #
    def syto_filters_attrs_map(*attrs_map)
      @syto_attrs_map = attrs_map
    end

    # Getter for @syto_attrs_map
    #
    def attrs_map
      @syto_attrs_map
    end

    # Filtering method
    #
    # @param [Hash] params
    #
    # @return [ActiveRecord::Relation]
    #
    def filter_by(params)
      return all if params.blank? || params.empty?

      @filter_klass ||= Syto::Base
      @filter_klass.new(self, all, params.symbolize_keys).perform
    end
  end

  # Base class for filters implementation
  #
  class Base
    attr_accessor :result, :params, :base_class

    # @param [Class] base_class
    # @param [ActiveRecord::Relation] result
    # @param [Hash] params
    #
    def initialize(base_class, result, params)
      @base_class = base_class
      @result     = result
      @params     = params
      @attrs_map  = (base_class.attrs_map || []) + (self.class.attrs_map || [])
    end

    def perform
      filter_by_attrs_map

      extended_filters

      result
    end

    def extended_filters
      puts "[WARNING] Syto filters not defined for #{self.class.name}"
    end

    class << self
      attr_reader :attrs_map

      def filters_attrs_map(*attrs)
        @attrs_map = attrs
      end
    end

    private

    def filter_by_attrs_map
      return unless @attrs_map

      @attrs_map.flatten.each do |filter|
        case filter
        when Symbol, String
          scalar_filter(filter)
        when Hash
          hash_filter(filter)
        end
      end
    end

    # Filter by attribute
    #
    # @param [String, Symbol] key
    # @param [String, Symbol, NilClass] field_name
    #
    def scalar_filter(key, field_name = nil)
      return unless @params[key]

      field_name ||= key
      @result = @result.where(field_name => @params[key])
    end

    # Filter by attribute with options
    #
    # @param [Hash] keys
    #
    def hash_filter(keys)
      keys.each do |key, options|
        case options
        when String, Symbol
          scalar_filter key, options
        when Hash
          filter_hash_options(key, options)
        end
      end
    end

    def filter_hash_options(key, options)
      puts key
      puts options
      if options[:type] == :range
        filter_by_range key, options
      else
        filter_by_value key, options
      end
    end

    # Filter by single value
    #
    # @param [Symbol] key
    # @param [Hash] options
    #
    # available options:
    # - field
    # - case_insensitive
    #
    def filter_by_value(key, options = {})
      return unless @params.key?(key)

      options ||= {}

      field_name = options[:field] || key

      value = @params[key]

      @result = if options[:case_insensitive] && value.respond_to?(:downcase)
                  @result.where(result.arel_table[field_name].lower.in(value.downcase))
                else
                  @result.where(field_name => value)
                end
    end

    # Filter by range
    #
    # @param [Symbol] key
    # @param [Hash{Symbol->Object}] options
    #
    # available options:
    # - field
    # - key_from,
    # - key_to,
    #
    def filter_by_range(key, options = {})
      options ||= {}

      key_from   = options[:key_from] || :"#{key}_from"
      key_to     = options[:key_to]   || :"#{key}_to"
      field_name = options[:field]    || key
      value_from = @params[key_from]
      value_to   = @params[key_to]

      return if value_from.blank? && value_to.blank?

      @result = @result.where(field_name => (value_from..value_to))
    end
  end
end
