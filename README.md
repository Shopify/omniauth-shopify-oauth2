[![Build Status](https://github.com/Shopify/omniauth-shopify-oauth2/workflows/CI/badge.svg?branch=main)](https://github.com/Shopify/omniauth-shopify-oauth2/actions)

# OmniAuth Shopify

Shopify OAuth2 Strategy for OmniAuth 1.0.

## Installing

Add to your `Gemfile`:

```ruby
gem 'omniauth-shopify-oauth2'
```

Then `bundle install`.

## Usage

`OmniAuth::Strategies::Shopify` is simply a Rack middleware. Read [the OmniAuth 1.0 docs](https://github.com/intridea/omniauth) for detailed instructions.

Here's a quick example, adding the middleware to a Rails app in `config/initializers/omniauth.rb`:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :shopify, ENV['SHOPIFY_API_KEY'], ENV['SHOPIFY_SHARED_SECRET']
end
```

Authenticate the user by having them visit /auth/shopify with a `shop` query parameter of their shop's myshopify.com domain. For example, the following form could be used

```html
<form action="/auth/shopify" method="get">
  <label for="shop">Enter your store's URL:</label>
  <input type="text" name="shop" placeholder="your-shop-url.myshopify.com">
  <button type="submit">Log In</button>
</form>
```

Or without form `/auth/shopify?shop=your-shop-url.myshopify.com`
Alternatively you can put shop parameter to session as [Shopify App](https://github.com/Shopify/shopify_app) do

```ruby
session['shopify.omniauth_params'] = { shop: params[:shop] }
```

And finally it's possible to use your own query parameter by overriding default setup method. For example, like below:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :shopify,
    ENV['SHOPIFY_API_KEY'],
    ENV['SHOPIFY_SHARED_SECRET'],
    option :setup, proc { |env|
      strategy = env['omniauth.strategy']



      site = if strategy.request.params['site']
        "https://#{strategy.request.params['site']}"
      else
        ''
      end

      env['omniauth.strategy'].options[:client_options][:site] = site
    }
```

## Configuring

### Scope

You can configure the scope, which you pass in to the `provider` method via a `Hash`:

* `scope`: A comma-separated list of permissions you want to request from the user. See [the Shopify API docs](http://docs.shopify.com/api/tutorials/oauth) for a full list of available permissions.

For example, to request `read_products`, `read_orders` and `write_content` permissions and display the authentication page:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :shopify, ENV['SHOPIFY_API_KEY'], ENV['SHOPIFY_SHARED_SECRET'], :scope => 'read_products,read_orders,write_content'
end
```

### Online Access

Shopify offers two different types of access tokens: [online access and offline access](https://help.shopify.com/api/getting-started/authentication/oauth/api-access-modes). You can configure for online-access by passing the `per_user_permissions` option:

```
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :shopify, ENV['SHOPIFY_API_KEY'],
                     ENV['SHOPIFY_SHARED_SECRET'],
                     :scope => 'read_orders',
                     :per_user_permissions => true
end
```

## Authentication Hash

Here's an example *Authentication Hash* available in `request.env['omniauth.auth']`:

```ruby
{
  :provider => 'shopify',
  :uid => 'example.myshopify.com',
  :credentials => {
    :token => 'afasd923kjh0934kf', # OAuth 2.0 access_token, which you store and use to authenticate API requests
  }
}
```

## License

Copyright (c) 2012 by Shopify Inc

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
