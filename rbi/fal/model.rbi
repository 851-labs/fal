# typed: strict
# frozen_string_literal: true

module Fal
  class Model
    MODELS_PATH = T.let(T.unsafe(nil), String)

    sig { returns(String) }
    def endpoint_id; end

    sig { returns(T.nilable(String)) }
    def display_name; end

    sig { returns(T.nilable(String)) }
    def category; end

    sig { returns(T.nilable(String)) }
    def description; end

    sig { returns(T.nilable(String)) }
    def status; end

    sig { returns(T.nilable(T::Array[String])) }
    def tags; end

    sig { returns(T.nilable(String)) }
    def updated_at; end

    sig { returns(T.nilable(T::Boolean)) }
    def is_favorited; end

    sig { returns(T.nilable(String)) }
    def thumbnail_url; end

    sig { returns(T.nilable(String)) }
    def thumbnail_animated_url; end

    sig { returns(T.nilable(String)) }
    def model_url; end

    sig { returns(T.nilable(String)) }
    def github_url; end

    sig { returns(T.nilable(String)) }
    def license_type; end

    sig { returns(T.nilable(String)) }
    def date; end

    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    def group; end

    sig { returns(T.nilable(T::Boolean)) }
    def highlighted; end

    sig { returns(T.nilable(String)) }
    def kind; end

    sig { returns(T.nilable(T::Array[String])) }
    def training_endpoint_ids; end

    sig { returns(T.nilable(T::Array[String])) }
    def inference_endpoint_ids; end

    sig { returns(T.nilable(String)) }
    def stream_url; end

    sig { returns(T.nilable(Float)) }
    def duration_estimate; end

    sig { returns(T.nilable(T::Boolean)) }
    def pinned; end

    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    def openapi; end

    sig { params(attributes: T.untyped, client: Fal::Client).void }
    def initialize(attributes, client: Fal.client); end

    sig { returns(T.nilable(Fal::Price)) }
    def price; end

    sig { params(input: T.untyped, webhook_url: T.nilable(String)).returns(Fal::Request) }
    def run(input:, webhook_url: nil); end

    class << self
      sig { params(endpoint_id: String, client: Fal::Client).returns(T.nilable(Fal::Model)) }
      def find_by(endpoint_id:, client: Fal.client); end

      sig do
        params(
          client: Fal::Client,
          query: T.nilable(String),
          category: T.nilable(String),
          status: T.nilable(String),
          expand: T.nilable(T.any(String, T::Array[String])),
          block: T.proc.params(arg0: Fal::Model).void
        ).void
      end
      def each(client: Fal.client, query: nil, category: nil, status: nil, expand: nil, &block); end

      sig do
        params(
          client: Fal::Client,
          query: T.nilable(String),
          category: T.nilable(String),
          status: T.nilable(String),
          expand: T.nilable(T.any(String, T::Array[String]))
        ).returns(T::Array[Fal::Model])
      end
      def all(client: Fal.client, query: nil, category: nil, status: nil, expand: nil); end

      sig do
        params(
          query: T.nilable(String),
          category: T.nilable(String),
          status: T.nilable(String),
          expand: T.nilable(T.any(String, T::Array[String])),
          client: Fal::Client
        ).returns(T::Array[Fal::Model])
      end
      def search(query: nil, category: nil, status: nil, expand: nil, client: Fal.client); end
    end

    private

    sig { params(attributes: T.untyped).void }
    def reset_attributes(attributes); end
  end
end
