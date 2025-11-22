# frozen_string_literal: true

require_relative "telegram_entities/version"
require_relative "telegram_entities/entity_tools"
require_relative "telegram_entities/entities"
require_relative "telegram_entities/tdlib_converter"

module TelegramEntities
  class Error < StandardError; end

  # Alias for TelegramEntities::Entities
  def self.new(*args, **kwargs)
    Entities.new(*args, **kwargs)
  end

  # Delegate class methods to Entities
  def self.from_markdown(*args, **kwargs)
    Entities.from_markdown(*args, **kwargs)
  end

  def self.from_html(*args, **kwargs)
    Entities.from_html(*args, **kwargs)
  end

  # Convert TDLib formattedText to TelegramEntities
  #
  # @param data [Hash] TDLib formattedText data with keys: "text", "@type", "entities"
  # @return [Entities] Object containing message and entities
  def self.from_tdlib_formatted_text(data)
    text, entities = TdlibConverter.convert_tdlib_data(data)
    Entities.new(text, entities)
  end
end
