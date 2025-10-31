# typed: strict
# frozen_string_literal: true

module Fal
  class Price
    MODELS_PATH = T.let(T.unsafe(nil), String)
    PRICING_PATH = T.let(T.unsafe(nil), String)

    module Unit
      IMAGES = T.let(T.unsafe(nil), String)
      VIDEOS = T.let(T.unsafe(nil), String)
      MEGAPIXELS = T.let(T.unsafe(nil), String)
      GPU_SECONDS = T.let(T.unsafe(nil), String)
      GPU_MINUTES = T.let(T.unsafe(nil), String)
      GPU_HOURS = T.let(T.unsafe(nil), String)
    end

    sig { returns(String) }
    def endpoint_id; end

    sig { returns(Float) }
    def unit_price; end

    sig { returns(String) }
    def unit; end

    sig { returns(String) }
    def currency; end

    sig { params(attributes: T.untyped, client: Fal::Client).void }
    def initialize(attributes, client: Fal.client); end

    class << self
      sig { params(endpoint_id: String, client: Fal::Client).returns(T.nilable(Fal::Price)) }
      def find_by(endpoint_id:, client: Fal.client); end

      sig { params(client: Fal::Client, block: T.proc.params(arg0: Fal::Price).void).void }
      def each(client: Fal.client, &block); end

      sig { params(client: Fal::Client).returns(T::Array[Fal::Price]) }
      def all(client: Fal.client); end
    end

    private

    sig { params(attributes: T.untyped).void }
    def reset_attributes(attributes); end
  end
end
