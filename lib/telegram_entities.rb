# frozen_string_literal: true

require_relative "telegram_entities/version"
require_relative "telegram_entities/entity_tools"
require_relative "telegram_entities/entities"

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
end
