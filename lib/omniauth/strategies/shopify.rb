require 'omniauth/strategies/oauth2'
require 'openssl'

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
      option :myshopify_domain, 'myshopify.com'

      uid { URI.parse(options[:client_options][:site]).host }

      def valid_site?
        !!(/\A(https|http)\:\/\/[a-zA-Z0-9][a-zA-Z0-9\-]*\.#{Regexp.quote(options[:myshopify_domain])}[\/]?\z/ =~ options[:client_options][:site])
      end

      def valid_hmac?
        digest = OpenSSL::Digest::SHA256.new("HMAC-SHA256")
        payload = request.params
          .inject({}) { |memo, (k, v)| memo[k] = v unless k == 'signature' || k == 'hmac'; memo }
          .sort_by { |(k, v)| k.to_s }
          .map { |(k, v)| "#{k}=#{v}" }
          .join("&")

        hmac_expected = OpenSSL::HMAC.hexdigest(digest, client.secret, payload)
        hmac_provided = request.params['hmac']

        hmac_provided == hmac_expected
      end

      def fix_https
        options[:client_options][:site].gsub!(/\Ahttp\:/, 'https:')
      end

      def setup_phase
        super
        fix_https
      end

      def request_phase
        if valid_site?
          super
        else
          fail!(:invalid_site)
        end
      end

      def callback_phase
        if valid_hmac?
          super
        else
          fail!(:invalid_hmac)
        end
      end

      def authorize_params
        super.tap do |params|
          params[:scope] ||= DEFAULT_SCOPE
        end
      end

      def callback_url
        options[:callback_url] || super
      end
    end
  end
end
