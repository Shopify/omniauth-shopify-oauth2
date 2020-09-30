require 'omniauth-shopify-oauth2'

class ScopesTest < Minitest::Test
  def test_scopes_normalize_to_reduce_read_scope_when_write_exists
    full_scopes = OmniAuth::Shopify::Scopes.new(['read_orders', 'read_products', 'write_orders'])
    expected_normalized_scopes = OmniAuth::Shopify::Scopes.new(['write_orders', 'read_products'])
    assert_equal expected_normalized_scopes, full_scopes.normalize
  end

  def test_scopes_normalize_scopes_with_unauthenticated_prefix
    full_scopes = OmniAuth::Shopify::Scopes.new(['unauthenticated_read_orders', 'read_products', 'unauthenticated_write_orders'])
    expected_normalized_scopes = OmniAuth::Shopify::Scopes.new(['unauthenticated_write_orders', 'read_products'])
    assert_equal expected_normalized_scopes, full_scopes.normalize
  end
end
