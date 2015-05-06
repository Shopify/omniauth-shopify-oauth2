require 'bundler/setup'
require 'sinatra/base'
require 'omniauth-shopify-oauth2'

SCOPE = 'read_products,read_orders,read_customers,write_shipping'

class App < Sinatra::Base
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
  provider :shopify, ENV['SHOPIFY_API_KEY'], ENV['SHOPIFY_SHARED_SECRET'],
           :scope => SCOPE,
           :setup => lambda { |env| params = Rack::Utils.parse_query(env['QUERY_STRING'])
                                    env['omniauth.strategy'].options[:client_options][:site] = "https://#{params['shop']}" }
end

run App.new
