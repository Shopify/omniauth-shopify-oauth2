module OmniAuth
  module Shopify
    class Scopes
      SCOPE_DELIMITER = ','

      def initialize(scope_names)
        if scope_names.is_a?(String)
          scope_names = scope_names.to_s.split(SCOPE_DELIMITER)
        end

        store_scopes(scope_names)
      end

      def to_s
        to_a.join(SCOPE_DELIMITER)
      end

      def to_a
        scopes.to_a
      end

      def ==(other)
        other.class == self.class &&
          scopes == other.scopes
      end

      alias :eql? :==

      def hash
        scopes.hash
      end

      protected

      attr_reader :scopes

      private

      def store_scopes(scope_names)
        scopes = scope_names.map(&:strip).reject(&:empty?).to_set
        ignore_scopes = scopes.map { |scope| scope =~ /\A(unauthenticated_)?write_(.*)\z/ && "#{$1}read_#{$2}" }.compact

        @scopes = scopes - ignore_scopes
      end
    end
  end
end
