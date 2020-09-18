source "https://rubygems.org"

gemspec

if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.2")
  gem 'rack', '~> 1.6'
end

group :development, :test do
  gem 'fakeweb', git: 'https://github.com/chrisk/fakeweb.git'
end
