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
    # @param [String. Symbol] attr
    # @param [Hash] params_key
    #
    def scalar_filter(attr, params_key = nil)
      params_key ||= attr
      params_key = params_key.to_sym
      return unless @params[params_key]

      @result = @result.where(attr => @params[params_key])
    end

    # Filter by attribute with options
    #
    # @param [Hash] attrs
    #
    def hash_filter(attrs)
      attrs.each do |attr, options|
        case options
        when String, Symbol
          scalar_filter attr, options
        when Hash
          filter_hash_options(attr, options)
        end
      end
    end

    def filter_hash_options(attr, options)
      filter_by_value attr, options if options.key?(:key)
      filter_by_range attr, options if options.key?(:key_from) && options.key?(:key_to)
    end

    # Filter by single value
    #
    # @param [Symbol] field_name
    # @param [Hash] options
    #
    def filter_by_value(field_name, options = {})
      options ||= {}

      key ||= options[:key] || field_name
      return unless @params.key?(key)

      value = @params[key]

      @result = if options[:case_insensitive] && value.respond_to?(:downcase)
                  @result.where(result.arel_table[field_name].lower.in(value.downcase))
                else
                  @result.where(field_name => value)
                end
    end

    # Filter by range
    #
    # @param [Symbol] field_name
    # @param [Hash{Symbol->Object}] options
    #
    # options:
    # - key_from,
    # - key_to,
    #
    def filter_by_range(field_name, options = {})
      key_from  = options[:key_from] || :"#{field_name}_from"
      key_to    = options[:key_to]   || :"#{field_name}_to"

      value_from = @params[key_from]
      value_to   = @params[key_to]

      return if value_from.blank? && value_to.blank?

      @result = @result.where(field_name => (value_from..value_to))
    end
  end
end
