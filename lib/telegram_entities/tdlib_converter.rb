# frozen_string_literal: true

module TelegramEntities
  # Converter for TDLib formattedText to TelegramEntities format
  module TdlibConverter
    # Mapping from TDLib entity types to TelegramEntities types
    TYPE_MAPPING = {
      "textEntityTypeMention" => "mention",
      "textEntityTypeHashtag" => "hashtag",
      "textEntityTypeCashtag" => "cashtag",
      "textEntityTypeBotCommand" => "bot_command",
      "textEntityTypeUrl" => "url",
      "textEntityTypeEmailAddress" => "email",
      "textEntityTypePhoneNumber" => "phone",
      "textEntityTypeBankCardNumber" => "bank_card",
      "textEntityTypeBold" => "bold",
      "textEntityTypeItalic" => "italic",
      "textEntityTypeUnderline" => "underline",
      "textEntityTypeStrikethrough" => "strike",
      "textEntityTypeSpoiler" => "spoiler",
      "textEntityTypeCode" => "code",
      "textEntityTypePre" => "pre",
      "textEntityTypePreCode" => "pre",
      "textEntityTypeBlockQuote" => "blockquote",
      "textEntityTypeExpandableBlockQuote" => "expandable_blockquote",
      "textEntityTypeTextUrl" => "text_url",
      "textEntityTypeMentionName" => "mention_name",
      "textEntityTypeCustomEmoji" => "custom_emoji",
      "textEntityTypeMediaTimestamp" => "media_timestamp"
    }.freeze

    # Convert TDLib formattedText data to TelegramEntities format
    #
    # @param data [Hash] TDLib formattedText data with keys: "text", "@type", "entities"
    # @return [Array<String, Array<Hash>>] Array containing text and converted entities
    def self.convert_tdlib_data(data)
      text = data["text"] || ""
      tdlib_entities = data["entities"] || []

      converted_entities = tdlib_entities.map do |entity|
        convert_entity(entity)
      end.compact

      [text, converted_entities]
    end

    # Convert a single TDLib entity to TelegramEntities format
    #
    # @param entity [Hash] TDLib entity with keys: "type", "offset", "length"
    # @return [Hash, nil] Converted entity or nil if type is not supported
    def self.convert_entity(entity)
      entity_type = entity["type"]
      return nil unless entity_type.is_a?(Hash)

      tdlib_type = entity_type["@type"]
      telegram_type = TYPE_MAPPING[tdlib_type]
      return nil unless telegram_type

      converted = {
        "type" => telegram_type,
        "offset" => entity["offset"] || 0,
        "length" => entity["length"] || 0
      }

      # Handle special fields based on entity type
      case tdlib_type
      when "textEntityTypeTextUrl"
        converted["url"] = entity_type["url"] if entity_type["url"]
      when "textEntityTypeMentionName"
        if entity_type["user_id"]
          converted["user"] = {"id" => entity_type["user_id"]}
        end
      when "textEntityTypeCustomEmoji"
        converted["custom_emoji_id"] = entity_type["custom_emoji_id"] if entity_type["custom_emoji_id"]
      when "textEntityTypePreCode"
        converted["language"] = entity_type["language"] if entity_type["language"]
      when "textEntityTypePre"
        converted["language"] = entity_type["language"] if entity_type["language"]
      when "textEntityTypeMediaTimestamp"
        converted["media_timestamp"] = entity_type["media_timestamp"] if entity_type["media_timestamp"]
      end

      converted
    end

    private_class_method :convert_entity
  end
end
