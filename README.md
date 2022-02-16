# Syto

Simple and lightweight library to filter data for Ruby on Rails models

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'syto'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install syto

## Usage

Initialize Syto in AR model 

Define filters for attributes `country`, `area_id` and `rate`

```ruby
# app/model/user.rb
class User < ActiveModel
  include Syto
  syto_attrs_map :active,                             # filter by users.active
                 country: { case_insensitive: true }, # allows to filter by 'users.country'
                 region: { field: :area_id },         # allows to filter by 'users.area_id' with "region" key in params 
                 rate: { type: :range },              # allows to filter by 'users.rate' with "rate_from" and "rate_to" keys in params
                 date: { type: :range, field: :created_at,        
                         key_from: :start_date, key_to: :end_date } # filter by 'users.created_at'
end
```

Define custom filters in class

```ruby
# app/models/post.rb
class Post < ActiveModel
  include Syto
  syto_filters_class PostFilters
end
```

Tip: There are 3 methods available in Syto  for use in `extended_filters`:
`base_class`, `params` and `result`

```ruby
# app/models/concerns/post_filter.rb
class PostFilters < Syto
    # map for converting params { author: 52, strat_date: '2020-01-01', end_date: '2021-12-31' }
    # to query like WHERE user_id = 52 AND created_at BETWEEN '2020-01-01' AND '2021-12-31'
    filters_attrs_map author: :user_id,
                      date: { field: :created_at, type: :range, key_from: :start_date, key_to: :end_date }
    
  def extended_filters
    # base_class contains Post
    return if params[:published].blank?

    self.result = result.where(published: params[:published])
    filter_by_range(:published, field: :published_at, key_from: :pub_from, key_to: :pub_to)
  end
end
```

Use in code:

```ruby
params = { author: 21, start_date: '2022-01-01' }
User.filter_by(params) # where user_id = 21 and created_at >= '2022-01-01'
```

```ruby
params = { country: 'UA', rate_from: 2, rate_to: 3 }
User.filter_by(params)
```

```ruby
params = { pub_from: '2021-01-01' }
Post.filter_by(params) # select published posts from 2021
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/p9436/syto.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
