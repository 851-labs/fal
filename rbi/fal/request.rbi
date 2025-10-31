# typed: strict
# frozen_string_literal: true

module Fal
  class Request
    sig { returns(String) }
    def id; end

    sig { returns(String) }
    def status; end

    sig { returns(T.nilable(Integer)) }
    def queue_position; end

    sig { returns(T.untyped) }
    def logs; end

    sig { returns(T.untyped) }
    def response; end

    sig { returns(String) }
    def endpoint_id; end

    sig do
      params(
        attributes: T.untyped,
        endpoint_id: String,
        client: Fal::Client
      ).void
    end
    def initialize(attributes, endpoint_id:, client:); end

    class << self
      sig do
        params(
          endpoint_id: String,
          input: T.untyped,
          client: Fal::Client,
          webhook_url: T.nilable(String)
        ).returns(Fal::Request)
      end
      def create!(endpoint_id:, input:, client:, webhook_url: nil); end

      sig do
        params(
          id: String,
          endpoint_id: String,
          client: Fal::Client,
          logs: T::Boolean
        ).returns(Fal::Request)
      end
      def find_by!(id:, endpoint_id:, client:, logs: false); end

      sig do
        params(
          endpoint_id: String,
          input: T.untyped,
          client: Fal::Client,
          block: T.nilable(T.proc.params(arg0: T.untyped).void)
        ).returns(Fal::Request)
      end
      def stream!(endpoint_id:, input:, client: Fal.client, &block); end
    end

    sig { returns(String) }
    def endpoint_id_without_subpath; end

    sig { params(logs: T::Boolean).returns(Fal::Request) }
    def reload!(logs: false); end

    sig { returns(T.untyped) }
    def cancel!; end

    sig { returns(T::Boolean) }
    def in_queue?; end

    sig { returns(T::Boolean) }
    def in_progress?; end

    sig { returns(T::Boolean) }
    def completed?; end

    private

    sig { params(attributes: T.untyped).void }
    def reset_attributes(attributes); end
  end
end
