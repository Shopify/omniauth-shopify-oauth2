---
layout: index
---

[![Build Status](https://api.travis-ci.org/Shopify/omniauth-shopify-oauth2.png?branch=master)](http://travis-ci.org/Shopify/omniauth-shopify-oauth2)

## Installation

Add to your Gemfile:

	ruby
	gem 'omniauth-shopify-oauth2'

Then `bundle install`.

## Usage

`OmniAuth::Strategies::Shopify` is simply a Rack middleware. Read [the OmniAuth 1.0 docs](https://github.com/intridea/omniauth) for detailed instructions.

Here's a quick example, adding the middleware to a Rails app in `config/initializers/omniauth.rb`:

	ruby
	Rails.application.config.middleware.use OmniAuth::Builder do
	  provider :shopify, ENV['SHOPIFY_API_KEY'], ENV['SHOPIFY_SHARED_SECRET']
	end

## Configuration

You can configure the scope, which you pass in to the `provider` method via a `Hash`:

* `scope`: A comma-separated list of permissions you want to request from the user. See [the Shopify API docs](http://docs.shopify.com/api/tutorials/oauth) for a full list of available permissions.

* `setup`: A lambda which dynamically sets the `site`. You must initiate the OmniAuth process by passing in a `shop` query parameter of the shop you're requesting permissions for. Ex. http://myapp.com/auth/shopify?shop=example.myshopify.com

For example, to request `read_products`, `read_orders` and `write_content` permissions and display the authentication page:

	ruby
	Rails.application.config.middleware.use OmniAuth::Builder do
	  provider :shopify, ENV['SHOPIFY_API_KEY'], ENV['SHOPIFY_SHARED_SECRET'],
	            :scope => 'read_products,read_orders,write_content',
	            :setup => lambda { |env| params = Rack::Utils.parse_query(env['QUERY_STRING'])
	                                     env['omniauth.strategy'].options[:client_options][:site] = "https://#{params['shop']}" }
	end

### Authentication Hash

Here's an example *Authentication Hash* available in `request.env['omniauth.auth']`:

```ruby
{
  :provider => 'shopify',
  :credentials => {
    :token => 'afasd923kjh0934kf', # OAuth 2.0 access_token, which you store and use to authenticate API requests
  }
}
```

## License

Copyright (c) 2012 Shopify | Released under the [MIT-LICENSE](http://opensource.org/licenses/MIT)