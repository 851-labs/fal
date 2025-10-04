# frozen_string_literal: true

module Fal
  # Represents a queued request submitted to a fal model endpoint.
  # Provides helpers to create, query status, cancel, and fetch response payloads
  # using the Queue API described in the fal docs.
  # See: https://docs.fal.ai/model-apis/model-endpoints/queue
  class Request
    # Request status values returned by the Queue API.
    module Status
      # @return [String]
      IN_QUEUE = "IN_QUEUE"
      # @return [String]
      IN_PROGRESS = "IN_PROGRESS"
      # @return [String]
      COMPLETED = "COMPLETED"
    end

    # @return [String] The request identifier (request_id)
    attr_reader :id
    # @return [String] The current status, one of Fal::Request::Status constants
    attr_reader :status
    # @return [Integer, nil] The current position in the queue, if available
    attr_reader :queue_position
    # @return [Array<Hash>, nil] Log entries when requested via logs=1
    attr_reader :logs
    # @return [Hash, nil] Response payload when status is COMPLETED
    attr_reader :response
    # @return [String] The model identifier used when creating this request
    attr_reader :model_id

    # @param attributes [Hash] Raw attributes from fal Queue API
    # @param model_id [String] Model ID in "namespace/name" format
    # @param client [Fal::Client] HTTP client to use for subsequent calls
    def initialize(attributes, model_id:, client: Fal.client)
      @client = client
      @model_id = model_id
      reset_attributes(attributes)
    end

    class << self
      # Create a new queued request for a model.
      # Corresponds to POST https://queue.fal.run/{model_id}
      # Optionally appends fal_webhook query param per docs.
      # @param model_id [String]
      # @param input [Hash]
      # @param webhook_url [String, nil]
      # @param client [Fal::Client]
      # @return [Fal::Request]
      def create!(model_id:, input:, webhook_url: nil, client: Fal.client)
        path = "/#{model_id}"
        body = input || {}
        path = "#{path}?fal_webhook=#{CGI.escape(webhook_url)}" if webhook_url
        attrs = client.post(path, body)
        new(attrs, model_id: model_id, client: client)
      end

      # Find the current status for a given request.
      # Corresponds to GET https://queue.fal.run/{model_id}/requests/{request_id}/status
      # @param id [String]
      # @param model_id [String]
      # @param logs [Boolean] include logs if true
      # @param client [Fal::Client]
      # @return [Fal::Request]
      def find_by!(id:, model_id:, logs: false, client: Fal.client)
        model_id_without_subpath = model_id.split("/").slice(0, 2).join("/")
        attrs = client.get("/#{model_id_without_subpath}/requests/#{id}/status", query: (logs ? { logs: 1 } : nil))
        new(attrs, model_id: model_id, client: client)
      end

      # Stream a synchronous request using SSE and yield response chunks as they arrive.
      # It returns a Fal::Request initialized with the last streamed data in the response field.
      # @param model_id [String]
      # @param input [Hash]
      # @param client [Fal::Client]
      # @yield [chunk] yields each parsed chunk Hash from the stream
      # @yieldparam chunk [Hash]
      # @return [Fal::Request]
      def stream!(model_id:, input:, client: Fal.client, &block)
        path = "/#{model_id}/stream"
        last_data = nil

        Stream.new(path: path, input: input, client: client).each do |event|
          data = event["data"]
          last_data = data
          block&.call(data)
        end

        # Wrap last chunk into a Request-like object for convenience
        # Build attributes from last event, using inner response if available
        response_payload = if last_data&.key?("response")
                             last_data["response"]
                           else
                             last_data
                           end
        attrs = {
          "request_id" => last_data && last_data["request_id"],
          "status" => last_data && last_data["status"],
          "response" => response_payload
        }.compact
        new(attrs, model_id: model_id, client: client)
      end
    end

    # @return [String] The model ID without the subpath
    def model_id_without_subpath
      @model_id.split("/").slice(0, 2).join("/")
    end

    # Reload the current status from the Queue API.
    # @param logs [Boolean] include logs if true
    # @return [Fal::Request]
    def reload!(logs: false)
      if @status == Status::IN_PROGRESS || @status == Status::IN_QUEUE
        attrs = @client.get("/#{model_id_without_subpath}/requests/#{@id}/status", query: (logs ? { logs: 1 } : nil))
        reset_attributes(attrs)
      end

      @response = @client.get("/#{model_id_without_subpath}/requests/#{@id}") if @status == Status::COMPLETED

      self
    end

    # Attempt to cancel the request if still in queue.
    # @return [Hash] cancellation response
    def cancel!
      @client.put("/#{model_id_without_subpath}/requests/#{@id}/cancel")
    end

    # @return [Boolean]
    def in_queue?
      @status == Status::IN_QUEUE
    end

    # @return [Boolean]
    def in_progress?
      @status == Status::IN_PROGRESS
    end

    # @return [Boolean]
    def completed?
      @status == Status::COMPLETED
    end

    private

    # Normalize attributes from different Queue API responses.
    # @param attributes [Hash]
    # @return [void]
    def reset_attributes(attributes)
      @id = attributes["request_id"] || @id
      # Default to IN_QUEUE if no status provided and no previous status
      @status = attributes["status"] || @status || Status::IN_QUEUE
      @queue_position = attributes["queue_position"]
      @logs = attributes["logs"]
      @response = attributes["response"]
    end
  end
end
