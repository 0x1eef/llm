# frozen_string_literal: true

module LLM
  ##
  # The Anthropic class implements a provider for
  # [Anthropic](https://www.anthropic.com)
  class Anthropic < Provider
    require_relative "anthropic/response_parser"

    HOST = "api.anthropic.com"
    DEFAULT_PARAMS = {model: "claude-3-5-sonnet-20240620"}.freeze

    ##
    # @param secret (see LLM::Provider#initialize)
    def initialize(secret)
      super(secret, HOST)
    end

    def embed(input, **params)
      req = Net::HTTP::Post.new ["api.voyageai.com/v1", "embeddings"].join("/")
      body = {input:, model: "voyage-2"}.merge!(params)
      req = preflight(req, body)
      res = request @http, req
      Response::Embedding.new(res.body, self)
    end

    def complete(message, **params)
      req = Net::HTTP::Post.new ["/v1", "messages"].join("/")
      messages = [*(params.delete(:messages) || []), message]
      params = DEFAULT_PARAMS.merge(params)
      body = {messages: messages.map(&:to_h)}.merge!(params)
      req = preflight(req, body)
      res = request @http, req
      Response::Completion.new(res.body, self).extend(response_parser)
    end

    private

    def auth(req)
      req["x-api-key"] = @secret
    end

    def response_parser
      LLM::Anthropic::ResponseParser
    end

    def transform_prompt(prompt)
      return unless URI === prompt
      [{
        type: :image,
        source: {
          type: :base64,
          media_type: prompt.content_type,
          data: [prompt.to_s].pack('m0')
        }
      }]
    end
  end
end
