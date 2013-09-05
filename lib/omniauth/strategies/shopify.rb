require 'omniauth/strategies/oauth2'

module OmniAuth
  module Strategies
    class Shopify < OmniAuth::Strategies::OAuth2
      # Available scopes: content themes products customers orders script_tags shipping
      # read_*  or write_*
      DEFAULT_SCOPE = 'read_products'

      option :client_options, {
        :authorize_url => '/admin/oauth/authorize',
        :token_url => '/admin/oauth/access_token'
      }

      option :callback_url

      option :provider_ignores_state, true

      uid { request.env["rack.request.query_hash"]["shop"] }

      info { { name: shop_name } }

      def shop_name
        request.env["rack.request.query_hash"]["shop"].sub('.myshopify.com', '')
      end

      def authorize_params
        super.tap do |params|
          params[:scope] ||= DEFAULT_SCOPE
        end
      end

      def callback_url
        options.callback_url || super
      end
    end
  end
end
