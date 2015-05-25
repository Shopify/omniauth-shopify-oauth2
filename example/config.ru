require 'bundler/setup'
require 'sinatra/base'
require 'omniauth-shopify-oauth2'

SCOPE = 'read_products,read_orders,read_customers,write_shipping'
SHOPIFY_API_KEY = ENV['SHOPIFY_API_KEY']
SHOPIFY_SHARED_SECRET = ENV['SHOPIFY_SHARED_SECRET']

unless SHOPIFY_API_KEY && SHOPIFY_SHARED_SECRET
  abort("SHOPIFY_API_KEY and SHOPIFY_SHARED_SECRET environment variables must be set")
end

class App < Sinatra::Base
  get '/' do
    <<-HTML
    <html>
    <head>
      <title>Shopify Oauth2</title>
    </head>
    <body>
      <form action="/auth/shopify" method="get">
      <label for="shop">Enter your store's URL:</label>
      <input type="text" name="shop" placeholder="your-shop-url.myshopify.com">
      <button type="submit">Log In</button>
      </form>
    </body>
    </html>
    HTML
  end

  get '/auth/:provider/callback' do
    <<-HTML
    <html>
    <head>
      <title>Shopify Oauth2</title>
    </head>
    <body>
      <h3>Authorized</h3>
      <p>Shop: #{request.env['omniauth.auth'].uid}</p>
      <p>Token: #{request.env['omniauth.auth']['credentials']['token']}</p>
    </body>
    </html>
    HTML
  end

  get '/auth/failure' do
    <<-HTML
    <html>
    <head>
      <title>Shopify Oauth2</title>
    </head>
    <body>
      <h3>Failed Authorization</h3>
      <p>Message: #{params[:message]}</p>
    </body>
    </html>
    HTML
  end
end

use Rack::Session::Cookie, secret: SecureRandom.hex(64)

use OmniAuth::Builder do
  provider :shopify, SHOPIFY_API_KEY, SHOPIFY_SHARED_SECRET, :scope => SCOPE
end

run App.new
