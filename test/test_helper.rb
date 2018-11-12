$: << File.expand_path("../../lib", __FILE__)
require 'bundler/setup'
require 'omniauth-shopify-oauth2'

require 'minitest/autorun'
require 'fakeweb'
require 'json'
require 'active_support/core_ext/hash'

OmniAuth.config.logger = Logger.new(nil)
FakeWeb.allow_net_connect = false
