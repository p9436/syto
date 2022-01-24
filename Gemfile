# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in syto.gemspec
gemspec

group :test do
  gem 'codecov', require: false
  gem 'minitest'
  gem 'minitest-reporters'
  gem 'rubocop'
  gem 'rubocop-minitest'
  gem 'sqlite3'
end
