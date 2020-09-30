module OmniAuth
  module Shopify
    class Scopes
      SCOPE_DELIMITER = ','

      def self.deserialize(scopes)
        new(scopes.to_s.split(SCOPE_DELIMITER))
      end

      def initialize(scope_names)
        @scopes = scope_names.to_set
      end

      def normalize
        scope_list = scopes.map(&:strip).reject(&:empty?)
        ignore_scopes = scope_list.map { |scope| scope =~ /\A(unauthenticated_)?write_(.*)\z/ && "#{$1}read_#{$2}" }.compact

        Scopes.new(scope_list - ignore_scopes)
      end

      def serialize
        to_a.join(SCOPE_DELIMITER)
      end

      def ==(other)
        other.class == self.class &&
          scopes == other.scopes
      end

      alias :eql? :==

      def hash
        scopes.hash
      end

      def to_a
        scopes.to_a
      end

      protected

      attr_reader :scopes
    end
  end
end
