# typed: strict
# frozen_string_literal: true

module Fal
  class WebhookRequest
    sig { returns(T.nilable(String)) }
    def request_id; end

    sig { returns(T.nilable(String)) }
    def gateway_request_id; end

    sig { returns(T.nilable(String)) }
    def status; end

    sig { returns(T.nilable(String)) }
    def error; end

    sig { returns(T.untyped) }
    def response; end

    sig { returns(T.untyped) }
    def logs; end

    sig { returns(T.untyped) }
    def metrics; end

    sig { returns(T.untyped) }
    def raw; end

    sig { params(attributes: T.untyped).void }
    def initialize(attributes); end

    class << self
      sig { params(json: String).returns(Fal::WebhookRequest) }
      def from_json(json); end

      sig { params(request: T.untyped).returns(Fal::WebhookRequest) }
      def from_rack_request(request); end

      sig { params(payload: T.untyped).returns(Fal::WebhookRequest) }
      def from_hash(payload); end
    end

    sig { returns(T::Boolean) }
    def success?; end

    sig { returns(T::Boolean) }
    def error?; end

    sig { returns(T.untyped) }
    def payload; end

    sig { returns(T.untyped) }
    def error_detail; end

    private

    sig { params(attributes: T.untyped).void }
    def reset_attributes(attributes); end
  end
end
