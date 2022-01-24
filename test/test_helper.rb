# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('lib', __dir__)

require 'syto'
require 'active_record'
require 'minitest/autorun'

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

ActiveRecord::Schema.define(version: 1) do
  create_table :entities do |t|
    t.string   :name
    t.string   :color
    t.integer  :weight
    t.integer  :price
    t.decimal  :ratio

    t.integer  :size_x
    t.integer  :size_y
    t.string   :model_number
    t.string   :serial_number

    t.datetime :created_at
  end
end

module Entities
  class Filters < Syto::Base
    def extended_filters
      filter_by_low_price
      filter_by_value(:name, { key: :name })
      filter_by_value(:color, { key: :color, case_insensitive: true })
      filter_by_range(:weight, { key_from: :wgt_from, key_to: :wgt_to })
      filter_by_range(:rate, { key_from: :rate_from, key_to: :rate_to, range_from: 0, range_to: 100 })
      filter_by_range(:created_at, { key_from: :date_from, key_to: :date_to })
    end

    # Custom filter rule
    def filter_by_low_price
      self.result = result.where('price < ?', params[:price_less_than]) if params.key?(:price_less_than)
    end
  end

  class Entity < ::ActiveRecord::Base
    include Syto
    syto_attrs_map :serial_number,
                   'entities.model_number': :model,
                   'entities.size_x': { key: :width, case_insensitive: true },
                   'entities.size_y': { key_from: :height_from, key_to: :height_to }

    syto_filters_class ::Entities::Filters
  end
end
