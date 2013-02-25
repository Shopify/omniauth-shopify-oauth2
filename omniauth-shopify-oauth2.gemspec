# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'omniauth/shopify/version'

Gem::Specification.new do |s|
  s.name     = 'omniauth-shopify-oauth2'
  s.version  = OmniAuth::Shopify::VERSION
  s.authors  = ['Denis Odorcic']
  s.email    = ['denis.odorcic@shopify.com']
  s.summary  = 'Shopify strategy for OmniAuth'
  s.homepage = 'https://github.com/Shopify/omniauth-shopify-oauth2'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_runtime_dependency 'omniauth-oauth2', '~> 1.1.1'

  s.add_development_dependency 'rspec', '~> 2.7.0'
  s.add_development_dependency 'rake'
end
