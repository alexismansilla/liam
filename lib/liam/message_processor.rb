# frozen_string_literal: true

require 'json'
require 'forwardable'

module Liam
  class MessageProcessor
    extend Forwardable

    def initialize(message)
      @message = message
    end

    def self.process(message)
      raise UnexpectedMessageError, message unless message.is_a?(Aws::SQS::Types::Message)

      new(message).send(:process)
    end

    private

    attr_reader :message

    private(*def_delegator(:message, :body))
    private(*def_delegator(:processor, :process))

    def parsed_message
      JSON.parse(body)
    end

    def processor
      Object.const_get(message_topic_name).new(parsed_message['Message'])
    rescue NameError => e
      raise UninitializedMessageProcessorError, e
    end

    def message_topic_name
      message_attribute_value.sub('_', '::').gsub(/(?<=^)(.*)(?=::)/, &:capitalize)
    end

    def message_attribute_value
      parsed_message.dig('MessageAttributes', 'event_name', 'Value').tap do |value|
        raise MessageWithoutValueAttributeError unless value
      end
    end
  end
end
