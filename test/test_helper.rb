$: << File.expand_path("../../lib", __FILE__)
require 'bundler/setup'
require 'omniauth-shopify-oauth2'

require 'minitest/autorun'
require 'rack/session'
require 'fakeweb'
require 'json'
require 'active_support'
require 'active_support/core_ext/hash'

OmniAuth.config.logger = Logger.new(nil)
OmniAuth.config.allowed_request_methods = [:post, :get]

FakeWeb.allow_net_connect = false
