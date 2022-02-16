# frozen_string_literal: true

require 'test_helper'

class FilterTest < Minitest::Test
  def test_attrs_map_setter
    params = { author: 1 }
    sql = Comments::Comment.filter_by(params).to_sql
    assert_equal 'SELECT "comments".* FROM "comments" WHERE "comments"."user_id" = 1', sql
  end

  # filters_attrs_map date: { field: :created_at, type: :range, key_from: :start_date, key_to: :end_date }
  def test_attrs_map_range
    params = { start_date: '2022-01-01', end_date: '2022-12-31 2022-12-31 23:59:59' }
    sql = Comments::Comment.filter_by(params).to_sql
    assert_equal 'SELECT "comments".* FROM "comments" WHERE "comments"."created_at" '\
                     'BETWEEN \'2022-01-01 00:00:00\' AND \'2022-12-31 23:59:59\'', sql
  end

  # Test for `syto_attrs_map :serial_number`
  #
  def test_filter_map_attr_name
    params = { serial_number: '34294WA' }
    sql = Entities::Entity.filter_by(params).to_sql
    assert_equal 'SELECT "entities".* FROM "entities" WHERE "entities"."serial_number" = \'34294WA\'', sql
  end

  # Test for `syto_attrs_map 'entities.model_number': :model`
  #
  def test_filter_map_attr_alias
    params = { model: '118d' }
    sql = Entities::Entity.filter_by(params).to_sql
    assert_equal 'SELECT "entities".* FROM "entities" WHERE "entities"."model_number" = \'118d\'', sql
  end

  # Test for `'entities.size_x': { key: :width }`
  #
  def test_filter_map_attr_value
    params = { width: 50 }
    sql = Entities::Entity.filter_by(params).to_sql
    assert_equal 'SELECT "entities".* FROM "entities" WHERE "entities"."size_x" = 50', sql
  end

  # Test for `full_name: { field: :'entities.name', case_insensitive: true }`
  #
  def test_filter_map_attr_ci
    params = { full_name: 'Alice' }
    sql = Entities::Entity.filter_by(params).to_sql
    assert_equal 'SELECT "entities".* FROM "entities" WHERE LOWER("entities"."name") IN (\'alice\')', sql
  end

  # Test for `'entities.size_y': { key_from: :height_from, key_to: :height_to }`
  #
  def test_filter_map_attr_range
    params = { height_from: 10, height_to: 20 }
    sql = Entities::Entity.filter_by(params).to_sql
    assert_equal 'SELECT "entities".* FROM "entities" WHERE "entities"."size_y" BETWEEN 10 AND 20', sql
  end

  def test_custom_filter
    params = { price_less_than: 38 }
    sql = Entities::Entity.filter_by(params).to_sql
    assert_equal 'SELECT "entities".* FROM "entities" WHERE (price < 38)', sql
  end

  def test_filter_by_value
    params = { name: 'Giraffe' }
    sql = Entities::Entity.filter_by(params).to_sql
    assert_equal 'SELECT "entities".* FROM "entities" WHERE "entities"."name" = \'Giraffe\'', sql
  end

  def test_filter_by_value_ci
    params = { color: 'Green' }
    sql = Entities::Entity.filter_by(params).to_sql
    assert_equal 'SELECT "entities".* FROM "entities" WHERE LOWER("entities"."color") IN (\'green\')', sql
  end

  def test_filter_by_range_between
    params = { wgt_gte: 100, wgt_lte: 200 }
    sql = Entities::Entity.filter_by(params).to_sql
    assert_equal 'SELECT "entities".* FROM "entities" WHERE "entities"."weight" BETWEEN 100 AND 200', sql
  end

  def test_filter_by_range_gte
    params = { wgt_gte: 100 }
    sql = Entities::Entity.filter_by(params).to_sql
    assert_equal 'SELECT "entities".* FROM "entities" WHERE "entities"."weight" >= 100', sql
  end

  def test_filter_by_range_lte
    params = { wgt_lte: 200 }
    sql = Entities::Entity.filter_by(params).to_sql
    assert_equal 'SELECT "entities".* FROM "entities" WHERE "entities"."weight" <= 200', sql
  end

  def test_filter_by_range_str
    params = { wgt_gte: '200', wgt_lte: '300' }
    sql = Entities::Entity.filter_by(params).to_sql
    assert_equal 'SELECT "entities".* FROM "entities" WHERE "entities"."weight" BETWEEN 200 AND 300', sql
  end

  def test_filter_by_range
    params = { rate_from: 0.5, rate_to: 0.7 }
    sql = Entities::Entity.filter_by(params).to_sql
    assert_equal 'SELECT "entities".* FROM "entities" WHERE "entities"."rate" BETWEEN 0.5 AND 0.7', sql
  end

  def test_filter_by_date
    params = { date_from: Date.new(2021, 1, 1), date_to: Date.new(2022, 11, 22) }
    sql = Entities::Entity.filter_by(params).to_sql
    assert_equal 'SELECT "entities".* FROM "entities" WHERE "entities"."created_at" '\
'BETWEEN \'2021-01-01\' AND \'2022-11-22\'', sql
  end
end
