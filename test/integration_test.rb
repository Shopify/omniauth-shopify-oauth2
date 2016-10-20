require_relative 'test_helper'

class IntegrationTest < Minitest::Test
  def setup
    build_app(scope: OmniAuth::Strategies::Shopify::DEFAULT_SCOPE)
  end

  def teardown
    FakeWeb.clean_registry
    FakeWeb.last_request = nil
  end

  def test_authorize
    response = authorize('snowdevil.myshopify.com')
    assert_equal 302, response.status
    assert_match %r{\A#{Regexp.quote(shopify_authorize_url)}}, response.location
    redirect_params = Rack::Utils.parse_query(URI(response.location).query)
    assert_equal "123", redirect_params['client_id']
    assert_equal "https://app.example.com/auth/shopify/callback", redirect_params['redirect_uri']
    assert_equal "read_products", redirect_params['scope']
    assert_nil redirect_params['grant_options']
  end

  def test_authorize_includes_auth_type_when_per_user_permissions_are_requested
    build_app(per_user_permissions: true)
    response = authorize('snowdevil.myshopify.com')
    redirect_params = Rack::Utils.parse_query(URI(response.location).query)
    assert_equal 'per-user', redirect_params['grant_options[]']
  end

  def test_authorize_overrides_site_with_https_scheme
    build_app setup: lambda { |env|
      params = Rack::Utils.parse_query(env['QUERY_STRING'])
      env['omniauth.strategy'].options[:client_options][:site] = "http://#{params['shop']}"
    }

    response = authorize('snowdevil.myshopify.com')
    assert_match %r{\A#{Regexp.quote(shopify_authorize_url)}}, response.location
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
      assert_auth_failure(response, 'invalid_site')

      response = callback(sign_params(shop: shop, code: code))
      assert_auth_failure(response, 'invalid_site')
    end
  end

  def test_callback
    access_token = SecureRandom.hex(16)
    code = SecureRandom.hex(16)
    expect_access_token_request(access_token, OmniAuth::Strategies::Shopify::DEFAULT_SCOPE)

    response = callback(sign_params(shop: 'snowdevil.myshopify.com', code: code, state: opts["rack.session"]["omniauth.state"]))

    assert_callback_success(response, access_token, code)
  end

  def test_callback_with_legacy_signature
    build_app scope: OmniAuth::Strategies::Shopify::DEFAULT_SCOPE
    access_token = SecureRandom.hex(16)
    code = SecureRandom.hex(16)
    expect_access_token_request(access_token, OmniAuth::Strategies::Shopify::DEFAULT_SCOPE)

    response = callback(sign_params(shop: 'snowdevil.myshopify.com', code: code, state: opts["rack.session"]["omniauth.state"]).merge(signature: 'ignored'))

    assert_callback_success(response, access_token, code)
  end

  def test_callback_custom_params
    access_token = SecureRandom.hex(16)
    code = SecureRandom.hex(16)

    expect_access_token_request(access_token, OmniAuth::Strategies::Shopify::DEFAULT_SCOPE)

    now = Time.now.to_i
    params = { shop: 'snowdevil.myshopify.com', code: code, timestamp: now, next: '/products?page=2&q=red%20shirt', state: opts["rack.session"]["omniauth.state"] }
    encoded_params = "code=#{code}&next=/products?page=2%26q=red%2520shirt&shop=snowdevil.myshopify.com&state=#{opts["rack.session"]["omniauth.state"]}&timestamp=#{now}"
    params[:hmac] = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA256.new, @secret, encoded_params)

    response = callback(params)

    assert_callback_success(response, access_token, code)
  end

  def test_callback_with_spaces_in_scope
    build_app scope: 'write_products, read_orders'
    access_token = SecureRandom.hex(16)
    code = SecureRandom.hex(16)
    expect_access_token_request(access_token, 'read_orders,write_products')

    response = callback(sign_params(shop: 'snowdevil.myshopify.com', code: code, state: opts["rack.session"]["omniauth.state"]))

    assert_callback_success(response, access_token, code)
  end

  def test_callback_rejects_invalid_hmac
    @secret = 'wrong_secret'
    response = callback(sign_params(shop: 'snowdevil.myshopify.com', code: SecureRandom.hex(16)))

    assert_auth_failure(response, 'invalid_signature')
  end

  def test_callback_rejects_old_timestamps
    expired_timestamp = Time.now.to_i - OmniAuth::Strategies::Shopify::CODE_EXPIRES_AFTER - 1
    response = callback(sign_params(shop: 'snowdevil.myshopify.com', code: SecureRandom.hex(16), timestamp: expired_timestamp))

    assert_auth_failure(response, 'invalid_signature')
  end

  def test_callback_rejects_missing_hmac
    code = SecureRandom.hex(16)

    response = callback(shop: 'snowdevil.myshopify.com', code: code, timestamp: Time.now.to_i)

    assert_auth_failure(response, 'invalid_signature')
  end

  def test_callback_rejects_body_params
    code = SecureRandom.hex(16)
    params = sign_params(shop: 'snowdevil.myshopify.com', code: code)
    body = Rack::Utils.build_nested_query(unsigned: 'value')

    response = request.get("https://app.example.com/auth/shopify/callback?#{Rack::Utils.build_query(params)}",
                           input: body,
                           "CONTENT_TYPE" => 'application/x-www-form-urlencoded')

    assert_auth_failure(response, 'invalid_signature')
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
    assert_match %r{\A#{Regexp.quote("https://snowdevil.myshopify.dev:3000/admin/oauth/authorize?")}}, response.location
    redirect_params = Rack::Utils.parse_query(URI(response.location).query)
    assert_equal 'read_products,read_orders,write_content', redirect_params['scope']
    assert_equal 'https://app.example.com/admin/auth/legacy/callback', redirect_params['redirect_uri']
  end

  def test_unnecessary_read_scopes_are_removed
    build_app scope: 'read_content,read_products,write_products',
              callback_path: '/admin/auth/legacy/callback',
              myshopify_domain: 'myshopify.dev:3000',
              setup: lambda { |env|
                shop = Rack::Request.new(env).GET['shop']
                shop += ".myshopify.dev:3000" unless shop.include?(".")
                env['omniauth.strategy'].options[:client_options][:site] = "https://#{shop}"
              }

    response = authorize('snowdevil')
    assert_equal 302, response.status
    redirect_params = Rack::Utils.parse_query(URI(response.location).query)
    assert_equal 'read_content,write_products', redirect_params['scope']
  end

  def test_callback_with_invalid_state_fails
    access_token = SecureRandom.hex(16)
    code = SecureRandom.hex(16)
    expect_access_token_request(access_token, OmniAuth::Strategies::Shopify::DEFAULT_SCOPE)

    response = callback(sign_params(shop: 'snowdevil.myshopify.com', code: code, state: 'invalid'))

    assert_equal 302, response.status
    assert_equal '/auth/failure?message=csrf_detected&strategy=shopify', response.location
  end

  def test_callback_with_mismatching_scope_fails
    access_token = SecureRandom.hex(16)
    code = SecureRandom.hex(16)
    expect_access_token_request(access_token, 'some_invalid_scope', nil)

    response = callback(sign_params(shop: 'snowdevil.myshopify.com', code: code, state: opts["rack.session"]["omniauth.state"]))

    assert_equal 302, response.status
    assert_equal '/auth/failure?message=invalid_scope&strategy=shopify', response.location
  end

  def test_callback_with_no_scope_fails
    access_token = SecureRandom.hex(16)
    code = SecureRandom.hex(16)
    expect_access_token_request(access_token, nil)

    response = callback(sign_params(shop: 'snowdevil.myshopify.com', code: code, state: opts["rack.session"]["omniauth.state"]))

    assert_equal 302, response.status
    assert_equal '/auth/failure?message=invalid_scope&strategy=shopify', response.location
  end

  def test_callback_with_missing_access_scope_fails
    build_app scope: 'first_scope,second_scope'

    access_token = SecureRandom.hex(16)
    code = SecureRandom.hex(16)
    expect_access_token_request(access_token, 'first_scope')

    response = callback(sign_params(shop: 'snowdevil.myshopify.com', code: code, state: opts["rack.session"]["omniauth.state"]))

    assert_equal 302, response.status
    assert_equal '/auth/failure?message=invalid_scope&strategy=shopify', response.location
  end

  def test_callback_with_extra_access_scope_fails
    build_app scope: 'first_scope,second_scope'

    access_token = SecureRandom.hex(16)
    code = SecureRandom.hex(16)
    expect_access_token_request(access_token, 'second_scope,first_scope,third_scope')

    response = callback(sign_params(shop: 'snowdevil.myshopify.com', code: code, state: opts["rack.session"]["omniauth.state"]))

    assert_equal 302, response.status
    assert_equal '/auth/failure?message=invalid_scope&strategy=shopify', response.location
  end

  def test_callback_with_scopes_out_of_order_works
    build_app scope: 'first_scope,second_scope'

    access_token = SecureRandom.hex(16)
    code = SecureRandom.hex(16)
    expect_access_token_request(access_token, 'second_scope,first_scope')

    response = callback(sign_params(shop: 'snowdevil.myshopify.com', code: code, state: opts["rack.session"]["omniauth.state"]))

    assert_callback_success(response, access_token, code)
  end

  def test_callback_with_extra_coma_works
    build_app scope: 'read_content,,write_products,'

    access_token = SecureRandom.hex(16)
    code = SecureRandom.hex(16)
    expect_access_token_request(access_token, 'read_content,write_products')

    response = callback(sign_params(shop: 'snowdevil.myshopify.com', code: code, state: opts["rack.session"]["omniauth.state"]))

    assert_callback_success(response, access_token, code)
  end

  def test_callback_when_per_user_permissions_are_present_but_not_requested
    build_app(scope: 'scope', per_user_permissions: false)

    access_token = SecureRandom.hex(16)
    code = SecureRandom.hex(16)
    expect_access_token_request(access_token, 'scope', { id: 1, email: 'bob@bobsen.com'})

    response = callback(sign_params(shop: 'snowdevil.myshopify.com', code: code, state: opts["rack.session"]["omniauth.state"]))

    assert_equal 302, response.status
    assert_equal '/auth/failure?message=invalid_permissions&strategy=shopify', response.location
  end

  def test_callback_when_per_user_permissions_are_not_present_but_requested
    build_app(scope: 'scope', per_user_permissions: true)

    access_token = SecureRandom.hex(16)
    code = SecureRandom.hex(16)
    expect_access_token_request(access_token, 'scope', nil)

    response = callback(sign_params(shop: 'snowdevil.myshopify.com', code: code, state: opts["rack.session"]["omniauth.state"]))

    assert_equal 302, response.status
    assert_equal '/auth/failure?message=invalid_permissions&strategy=shopify', response.location
  end

  def test_callback_works_when_per_user_permissions_are_present_and_requested
    build_app(scope: 'scope', per_user_permissions: true)

    access_token = SecureRandom.hex(16)
    code = SecureRandom.hex(16)
    expect_access_token_request(access_token, 'scope', { id: 1, email: 'bob@bobsen.com'})

    response = callback(sign_params(shop: 'snowdevil.myshopify.com', code: code, state: opts["rack.session"]["omniauth.state"]))

    assert_equal 200, response.status
  end

  private

  def sign_params(params)
    params = params.dup

    params[:timestamp] ||= Time.now.to_i

    encoded_params = OmniAuth::Strategies::Shopify.encoded_params_for_signature(params)
    params['hmac'] = OmniAuth::Strategies::Shopify.hmac_sign(encoded_params, @secret)
    params
  end

  def expect_access_token_request(access_token, scope, associated_user=nil)
    FakeWeb.register_uri(:post, "https://snowdevil.myshopify.com/admin/oauth/access_token",
                         body: JSON.dump(access_token: access_token, scope: scope, associated_user: associated_user),
                         content_type: 'application/json')
  end

  def assert_callback_success(response, access_token, code)
    token_request_params = Rack::Utils.parse_query(FakeWeb.last_request.body)
    assert_equal token_request_params['client_id'], '123'
    assert_equal token_request_params['client_secret'], @secret
    assert_equal token_request_params['code'], code

    assert_equal 'snowdevil.myshopify.com', @omniauth_result.uid
    assert_equal access_token, @omniauth_result.credentials.token
    assert_equal false, @omniauth_result.credentials.expires

    assert_equal 200, response.status
    assert_equal "OK", response.body
  end

  def assert_auth_failure(response, reason)
    assert_nil FakeWeb.last_request
    assert_equal 302, response.status
    assert_match %r{\A#{Regexp.quote("/auth/failure?message=#{reason}")}}, response.location
  end

  def build_app(options={})
    app = proc { |env|
      @omniauth_result = env['omniauth.auth']
      [200, {Rack::CONTENT_TYPE => "text/plain"}, "OK"]
    }

    opts["rack.session"]["omniauth.state"] = SecureRandom.hex(32)
    app = OmniAuth::Builder.new(app) do
      provider :shopify, '123', '53cr3tz', options
    end
    @secret = '53cr3tz'
    @app = Rack::Session::Cookie.new(app, secret: SecureRandom.hex(64))
  end

  def authorize(shop)
    request.get("https://app.example.com/auth/shopify?shop=#{CGI.escape(shop)}", opts)
  end

  def callback(params)
    request.get("https://app.example.com/auth/shopify/callback?#{Rack::Utils.build_query(params)}", opts)
  end

  def opts
    @opts ||= { "rack.session" => {} }
  end

  def request
    Rack::MockRequest.new(@app)
  end

  def shopify_authorize_url
    "https://snowdevil.myshopify.com/admin/oauth/authorize?"
  end
end
