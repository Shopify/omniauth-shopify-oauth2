require 'oauth2'

module OmniAuth
  module Shopify
    # Computes refresh_token_expires_at when the token is built, the same way
    # OAuth2::AccessToken computes expires_at from expires_in.
    class AccessToken < ::OAuth2::AccessToken
      attr_reader :refresh_token_expires_at

      def initialize(client, token, opts = {})
        opts = opts.dup
        @refresh_token_expires_at = opts.delete(:refresh_token_expires_at) || opts.delete('refresh_token_expires_at')
        super(client, token, opts)
        @refresh_token_expires_at &&=convert_expires_at(@refresh_token_expires_at)
        expires_in = (self[:refresh_token_expires_in] || self['refresh_token_expires_in']).to_i
        @refresh_token_expires_at ||= Time.now.to_i + expires_in if expires_in > 0
        @refresh_token_expires_at -= @expires_latency if @refresh_token_expires_at && @expires_latency
      end

      def to_hash
        hsh = super
        hsh[:refresh_token_expires_at] = refresh_token_expires_at if refresh_token_expires_at
        hsh
      end
    end
  end
end
