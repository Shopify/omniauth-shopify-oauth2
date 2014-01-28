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

      uid { URI.parse(options[:client_options][:site]).host }

      def valid_site?
        return /^(https|http)\:\/\/[a-zA-Z0-9][a-zA-Z0-9\-]*\.myshopify\.com[\/]?$/ =~ options[:client_options][:site]
      end

      def fix_https
        options[:client_options][:site].gsub!(/^http\:/, 'https:')
      end

      def setup_phase
        super
        raise CallbackError.new(nil, :invalid_site) unless valid_site?
        fix_https
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
