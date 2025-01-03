# frozen_string_literal: true

module LLM
  ##
  # The Ollama class implements a provider for
  # [Ollama](https://ollama.ai/)
  class Ollama < Provider
    require_relative "ollama/error_handler"
    require_relative "ollama/response_parser"

    HOST = "localhost"
    DEFAULT_PARAMS = {model: "llama3.2", stream: false}.freeze

    ##
    # @param secret (see LLM::Provider#initialize)
    def initialize(secret, **)
      super(secret, host: HOST, port: 11434, ssl: false, **)
    end

    ##
    # @see https://github.com/ollama/ollama/blob/main/docs/api.md#generate-a-chat-completion Ollama docs
    # @param prompt (see LLM::Provider#complete)
    # @param role (see LLM::Provider#complete)
    # @return (see LLM::Provider#complete)
    def complete(prompt, role = :user, **params)
      req = Net::HTTP::Post.new ["/api", "chat"].join("/")
      messages = [*(params.delete(:messages) || []), LLM::Message.new(role, transform_prompt(prompt))]
      params = DEFAULT_PARAMS.merge(params)
      body = {messages: messages.map(&:to_h)}.merge!(params)
      req = preflight(req, body)
      res = request(@http, req)
      Response::Completion.new(res.body, self).extend(response_parser)
    end

    ##
    # @param prompt (see LLM::Provider#transform_prompt)
    # @return (see LLM::Provider#transform_prompt)
    def transform_prompt(prompt)
      if URI === prompt
        [{type: :image_url, image_url: {url: prompt.to_s}}]
      else
        prompt
      end
    end

    private

    def auth(req)
      req["Authorization"] = "Bearer #{@secret}"
    end

    def response_parser
      LLM::Ollama::ResponseParser
    end

    def error_handler
      LLM::Ollama::ErrorHandler
    end
  end
end
