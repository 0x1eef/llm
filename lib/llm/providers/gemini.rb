# frozen_string_literal: true

module LLM
  ##
  # The Gemini class implements a provider for
  # [Gemini](https://ai.google.dev/)
  class Gemini < Provider
    require_relative "gemini/error_handler"
    require_relative "gemini/response_parser"
    require_relative "gemini/format"
    include Format

    HOST = "generativelanguage.googleapis.com"
    DEFAULT_PARAMS = {model: "gemini-1.5-flash"}.freeze

    ##
    # @param secret (see LLM::Provider#initialize)
    def initialize(secret, **)
      super(secret, host: HOST, **)
    end

    ##
    # @param input (see LLM::Provider#embed)
    # @return (see LLM::Provider#embed)
    def embed(input, **params)
      path = ["/v1beta/models", "text-embedding-004"].join("/")
      req = Net::HTTP::Post.new [path, "embedContent"].join(":")
      body = {content: {parts: [{text: input}]}}
      req = preflight(req, body)
      res = request @http, req
      Response::Embedding.new(res).extend(response_parser)
    end

    ##
    # @see https://ai.google.dev/api/generate-content#v1beta.models.generateContent Gemini docs
    # @param prompt (see LLM::Provider#complete)
    # @param role (see LLM::Provider#complete)
    # @return (see LLM::Provider#complete)
    def complete(prompt, role = :user, **params)
      params = DEFAULT_PARAMS.merge(params)
      path = ["/v1beta/models", params.delete(:model)].join("/")
      req = Net::HTTP::Post.new [path, "generateContent"].join(":")
      messages = [*(params.delete(:messages) || []), LLM::Message.new(role, prompt)]
      body = {contents: format(messages)}
      req = preflight(req, body)
      res = request(@http, req)
      Response::Completion.new(res).extend(response_parser)
    end

    private

    def auth(req)
      req.path.replace [req.path, URI.encode_www_form(key: @secret)].join("?")
    end

    def response_parser
      LLM::Gemini::ResponseParser
    end

    def error_handler
      LLM::Gemini::ErrorHandler
    end
  end
end
