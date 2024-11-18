# frozen_string_literal: true

module LLM
  ##
  # The Anthropic class implements a provider for
  # [Anthropic](https://www.anthropic.com)
  class Anthropic < Provider
    require_relative "anthropic/error_handler"
    require_relative "anthropic/response_parser"

    HOST = "api.anthropic.com"
    DEFAULT_PARAMS = {model: "claude-3-5-sonnet-20240620"}.freeze

    ##
    # @param secret (see LLM::Provider#initialize)
    def initialize(secret, **)
      super(secret, host: HOST, **)
    end

    ##
    # @param input (see LLM::Provider#embed)
    # @return (see LLM::Provider#embed)
    def embed(input, **params)
      req = Net::HTTP::Post.new ["api.voyageai.com/v1", "embeddings"].join("/")
      body = {input:, model: "voyage-2"}.merge!(params)
      req = preflight(req, body)
      res = request @http, req
      Response::Embedding.new(res.body, self)
    end

    def complete(prompt, role = :user, **params)
      req = Net::HTTP::Post.new ["/v1", "messages"].join("/")
      messages = [*(params.delete(:messages) || []), Message.new(role.to_s, prompt)]
      params = DEFAULT_PARAMS.merge(params)
      body = {messages: messages.map(&:to_h)}.merge!(params)
      req = preflight(req, body)
      res = request @http, req
      Response::Completion.new(res.body, self).extend(response_parser)
    end

    ##
    # @param prompt (see LLM::Provider#transform_prompt)
    # @return (see LLM::Provider#transform_prompt)
    def transform_prompt(prompt)
      if LLM::File === prompt
        raise TypeError, "#{self.class} does not support LLM::File objects"
      elsif URI === prompt
        [{
          type: :image,
          source: {
            type: :base64,
            media_type: prompt.content_type,
            data: [prompt.to_s].pack("m0")
          }
        }]
      else
        prompt
      end
    end

    private

    def auth(req)
      req["x-api-key"] = @secret
    end

    def response_parser
      LLM::Anthropic::ResponseParser
    end

    def error_handler
      LLM::Anthropic::ErrorHandler
    end
  end
end
