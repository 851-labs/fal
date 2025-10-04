# frozen_string_literal: true

module Fal
  # WebhookRequest parses incoming webhook payloads from fal and exposes
  # convenient helpers to inspect success/error and access the response payload.
  # Follows Rails-like naming with predicate helpers.
  class WebhookRequest
    # Webhook status values.
    module Status
      # @return [String]
      OK = "OK"
      # @return [String]
      ERROR = "ERROR"
    end

    # @return [String, nil] The request identifier
    attr_reader :request_id
    # @return [String, nil] The gateway request identifier, when present
    attr_reader :gateway_request_id
    # @return [String, nil] Webhook status (OK/ERROR) when provided
    attr_reader :status
    # @return [String, nil] Error message when provided
    attr_reader :error
    # @return [Hash, nil] Model-specific response payload
    attr_reader :response
    # @return [Array<Hash>, nil] Log entries, when present
    attr_reader :logs
    # @return [Hash, nil] Metrics, when present
    attr_reader :metrics
    # @return [Hash] The raw parsed payload
    attr_reader :raw

    # Initialize from a parsed payload Hash (string keys expected, tolerant of symbol keys).
    # @param attributes [Hash]
    def initialize(attributes)
      @raw = attributes
      reset_attributes(attributes)
    end

    class << self
      # Build from a JSON string body.
      # @param json [String]
      # @return [Fal::WebhookRequest]
      def from_json(json)
        new(JSON.parse(json))
      end

      # Build from a Rack::Request.
      # @param req [#body]
      # @return [Fal::WebhookRequest]
      def from_rack_request(req)
        body = req.body.read
        req.body.rewind if req.body.respond_to?(:rewind)
        from_json(body)
      end

      # Build from a Hash payload.
      # @param payload [Hash]
      # @return [Fal::WebhookRequest]
      def from_hash(payload)
        new(payload)
      end
    end

    # @return [Boolean]
    def success?
      @status == Status::OK || (
        @status.nil? && @error.nil?
      )
    end

    # @return [Boolean]
    def error?
      !success?
    end

    # Back-compat alias matching older naming (payload vs response).
    # @return [Hash, nil]
    def payload
      @response
    end

    # @return [String, nil] Any nested error detail
    def error_detail = @response&.dig(:detail)

    private

    def reset_attributes(attributes)
      attributes = Fal.deep_symbolize_keys(attributes)
      @request_id = attributes[:request_id]
      @gateway_request_id = attributes[:gateway_request_id]
      @status = attributes[:status]
      @error = attributes[:error]
      @response = attributes[:payload]
      @logs = attributes[:logs]
      @metrics = attributes[:metrics]
    end
  end
end
