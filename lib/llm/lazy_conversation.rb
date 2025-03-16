# frozen_string_literal: true

module LLM
  require_relative "message_queue"

  ##
  # {LLM::LazyConversation LLM::LazyConversation} provides a
  # conversation object that allows input prompts to be queued
  # and only sent to the LLM when a response is needed.
  #
  # @example
  #   llm = LLM.openai(key)
  #   bot = llm.chat("Be a helpful weather assistant", :system)
  #   bot.chat("What's the weather like in Rio?")
  #   bot.chat("What's the weather like in Algiers?")
  #   bot.messages.each do |message|
  #     # A single request is made at this point
  #   end
  class LazyConversation
    ##
    # @return [LLM::MessageQueue]
    attr_reader :messages

    ##
    # @param [LLM::Provider] provider
    #  A provider
    def initialize(provider)
      @provider = provider
      @messages = LLM::MessageQueue.new(provider)
    end

    ##
    # @param prompt (see LLM::Provider#prompt)
    # @return [LLM::Conversation]
    def chat(prompt, role = :user, **params)
      tap { @messages << [transform_prompt(prompt), role, params] }
    end

    private

    def transform_prompt(...)
      @provider.transform_prompt(...)
    end
  end
end
