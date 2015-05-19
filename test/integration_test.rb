require_relative 'test_helper'

class IntegrationTest < Minitest::Test
  def setup
    build_app
  end

  def teardown
    FakeWeb.clean_registry
    FakeWeb.last_request = nil
  end

  def test_authorize
    response = authorize('snowdevil.myshopify.com')
    assert_equal 302, response.status
    assert_match /\A#{Regexp.quote("https://snowdevil.myshopify.com/admin/oauth/authorize?")}/, response.location
    redirect_params = Rack::Utils.parse_query(URI(response.location).query)
    assert_equal "123", redirect_params['client_id']
    assert_equal "https://app.example.com/auth/shopify/callback", redirect_params['redirect_uri']
    assert_equal "read_products", redirect_params['scope']
  end

  def test_authorize_overrides_site_with_https_scheme
    build_app setup: lambda { |env|
      params = Rack::Utils.parse_query(env['QUERY_STRING'])
      env['omniauth.strategy'].options[:client_options][:site] = "http://#{params['shop']}"
    }

    response = authorize('snowdevil.myshopify.com')
    assert_match /\A#{Regexp.quote("https://snowdevil.myshopify.com/admin/oauth/authorize?")}/, response.location
  end

  def test_site_validation
    code = SecureRandom.hex(16)

    [
      'foo.example.com',                # shop doesn't end with .myshopify.com
      'http://snowdevil.myshopify.com', # shop contains protocol
      'snowdevil.myshopify.com/path',   # shop contains path
      'user@snowdevil.myshopify.com',   # shop contains user
      'snowdevil.myshopify.com:22',     # shop contains port
    ].each do |shop, valid|
      response = authorize(shop)
      assert_equal 302, response.status
      assert_match /\A#{Regexp.quote("/auth/failure?message=invalid_site")}/, response.location

      response = callback(shop: shop, code: code)
      assert_nil FakeWeb.last_request
      assert_equal 302, response.status
      assert_match /\A#{Regexp.quote("/auth/failure?message=invalid_site")}/, response.location
    end
  end

  def test_callback
    access_token = SecureRandom.hex(16)
    code = SecureRandom.hex(16)
    FakeWeb.register_uri(:post, "https://snowdevil.myshopify.com/admin/oauth/access_token",
                         body: JSON.dump(access_token: access_token),
                         content_type: 'application/json')

    response = callback(shop: 'snowdevil.myshopify.com', code: code)

    token_request_params = Rack::Utils.parse_query(FakeWeb.last_request.body)
    assert_equal token_request_params['client_id'], '123'
    assert_equal token_request_params['client_secret'], '53cr3tz'
    assert_equal token_request_params['code'], code

    assert_equal 'snowdevil.myshopify.com', @omniauth_result.uid
    assert_equal access_token, @omniauth_result.credentials.token
    assert_equal false, @omniauth_result.credentials.expires

    assert_equal 200, response.status
    assert_equal "OK", response.body
  end

  def test_provider_options
    build_app scope: 'read_products,read_orders,write_content',
              callback_path: '/admin/auth/legacy/callback',
              myshopify_domain: 'myshopify.dev:3000',
              setup: lambda { |env|
                shop = Rack::Request.new(env).GET['shop']
                shop += ".myshopify.dev:3000" unless shop.include?(".")
                env['omniauth.strategy'].options[:client_options][:site] = "https://#{shop}"
              }

    response = authorize('snowdevil')
    assert_equal 302, response.status
    assert_match /\A#{Regexp.quote("https://snowdevil.myshopify.dev:3000/admin/oauth/authorize?")}/, response.location
    redirect_params = Rack::Utils.parse_query(URI(response.location).query)
    assert_equal 'read_products,read_orders,write_content', redirect_params['scope']
    assert_equal 'https://app.example.com/admin/auth/legacy/callback', redirect_params['redirect_uri']
  end

  private

  def build_app(options={})
    app = proc { |env|
      @omniauth_result = env['omniauth.auth']
      [200, {Rack::CONTENT_TYPE => "text/plain"}, "OK"]
    }

    app = OmniAuth::Builder.new(app) do
      provider :shopify, '123', '53cr3tz', options
    end
    @app = Rack::Session::Cookie.new(app, secret: SecureRandom.hex(64))
  end

  def authorize(shop)
    request.get("https://app.example.com/auth/shopify?shop=#{CGI.escape(shop)}")
  end

  def callback(params)
    request.get("https://app.example.com/auth/shopify/callback?#{Rack::Utils.build_query(params)}")
  end

  def request
    Rack::MockRequest.new(@app)
  end
end
