require 'omniauth-shopify-oauth2'

class ScopesTest < Minitest::Test
  def test_scopes_normalize_to_reduce_read_scope_when_write_exists
    full_scopes = OmniAuth::Shopify::Scopes.new(['read_orders', 'read_products ', 'write_orders'])
    expected_normalized_scopes = OmniAuth::Shopify::Scopes.new(%w(write_orders read_products))
    assert_equal expected_normalized_scopes, full_scopes.normalize
  end

  def test_scopes_normalize_scopes_with_unauthenticated_prefix
    full_scopes = OmniAuth::Shopify::Scopes.new([' unauthenticated_read_orders', 'read_products', 'unauthenticated_write_orders'])
    expected_normalized_scopes = OmniAuth::Shopify::Scopes.new(%w(unauthenticated_write_orders read_products))
    assert_equal expected_normalized_scopes, full_scopes.normalize
  end

  def test_scopes_deserialize
    serialized_scopes = "read_products, write_orders"
    expected_scopes = OmniAuth::Shopify::Scopes.new(%w(write_orders read_products))
    deserialized_scopes = OmniAuth::Shopify::Scopes.deserialize(serialized_scopes)
    assert_equal expected_scopes, deserialized_scopes
  end

  def test_scopes_serialize
    deserialized_scopes = OmniAuth::Shopify::Scopes.deserialize(" read_products,write_orders,read_products")
    expected_scopes = OmniAuth::Shopify::Scopes.new(%w(read_products write_orders))
    serialized_scopes = deserialized_scopes.serialize
    assert_equal expected_scopes, OmniAuth::Shopify::Scopes.deserialize(serialized_scopes)
  end
end
