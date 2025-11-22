# frozen_string_literal: true

require "nokogiri"

module TelegramEntities
  # Class that represents a message + set of Telegram entities.
  class Entities
    attr_accessor :message, :entities

    # Creates an Entities container using a message and a list of entities.
    #
    # @param message [String] Converted message
    # @param entities [Array<Hash>] Converted entities
    def initialize(message, entities = [])
      @message = message
      @entities = entities
    end

    # Manually convert markdown to a message and a set of entities.
    #
    # @param markdown [String] Markdown text
    # @return [Entities] Object containing message and entities
    def self.from_markdown(markdown)
      markdown = markdown.tr("\r\n", "\n").strip
      message = ""
      message_len = 0
      entities = []
      offset = 0
      stack = []

      while offset < markdown.length
        # Find next special character
        special_chars = "*_~`[]|!\\"
        len = 0
        while offset + len < markdown.length && !special_chars.include?(markdown[offset + len])
          len += 1
        end

        piece = markdown[offset, len]
        offset += len

        if offset >= markdown.length
          message += piece
          break
        end

        char = markdown[offset]
        offset += 1
        next_char = markdown[offset]

        # Handle escape
        if char == "\\"
          message += piece + (next_char || "")
          message_len += EntityTools.mb_strlen(piece) + 1
          offset += 1 if next_char
          next
        end

        # Handle double characters
        if char == "_" && next_char == "_"
          offset += 1
          char = "__"
        elsif char == "|"
          if next_char == "|"
            offset += 1
            char = "||"
          else
            message += piece + char
            message_len += EntityTools.mb_strlen(piece) + 1
            next
          end
        elsif char == "!"
          if next_char == "["
            offset += 1
            char = "]("
          else
            message += piece + char
            message_len += EntityTools.mb_strlen(piece) + 1
            next
          end
        elsif char == "["
          char = "]("
        elsif char == "]"
          if stack.empty? || stack.last[0] != "]("
            message += piece + char
            message_len += EntityTools.mb_strlen(piece) + 1
            next
          end
          if next_char != "("
            stack.pop
            message += "[" + piece + char
            message_len += EntityTools.mb_strlen(piece) + 2
            next
          end
          offset += 1
          char = "]("
        elsif char == "`"
          message += piece
          message_len += EntityTools.mb_strlen(piece)

          token = "`"
          language = nil
          if next_char == "`" && markdown[offset + 1] == "`"
            token = "```"
            offset += 2
            lang_len = 0
            while offset + lang_len < markdown.length && !["\n", " "].include?(markdown[offset + lang_len])
              lang_len += 1
            end
            language = markdown[offset, lang_len] if lang_len > 0
            offset += lang_len
            offset += 1 if markdown[offset] == "\n"
          end

          piece = ""
          pos_close = offset
          found = false
          while pos_close < markdown.length
            pos_close = markdown.index(token, pos_close)
            unless pos_close
              found = false
              break
            end

            if pos_close > 0 && markdown[pos_close - 1] == "\\"
              piece += markdown[offset, pos_close - offset - 1] + token
              pos_close += token.length
              offset = pos_close
              next
            end
            found = true
            break
          end

          raise "Unclosed #{token} opened @ pos #{offset}!" unless found

          piece += markdown[offset, pos_close - offset]

          start = message_len
          message += piece
          piece_len = EntityTools.mb_strlen(piece)
          message_len += piece_len

          # Trim trailing whitespace from piece
          piece_bytes = piece.bytes
          piece_len_bytes = piece_bytes.length
          (piece_len_bytes - 1).downto(0) do |x|
            char = piece_bytes[x]
            break unless [32, 13, 10].include?(char) # space, \r, \n
            piece_len -= 1
          end

          if piece_len > 0
            entity = {
              "type" => ((token == "```") ? "pre" : "code"),
              "offset" => start,
              "length" => piece_len
            }
            entity["language"] = language if language
            entities << entity
          end

          offset = pos_close + token.length
          next
        end

        # Handle closing tag
        if !stack.empty? && stack.last[0] == char
          _, start = stack.pop

          if char == "]("
            pos_close = offset
            link = ""
            while pos_close < markdown.length
              pos_close = markdown.index(")", pos_close)
              break unless pos_close

              if pos_close > 0 && markdown[pos_close - 1] == "\\"
                link += markdown[offset, pos_close - offset - 1]
                offset = pos_close + 1
                next
              end
              link += markdown[offset, pos_close - offset]
              break
            end

            raise "Unclosed ) opened @ pos #{offset}!" unless pos_close

            entity = handle_link(link)
            offset = pos_close + 1
          else
            entity = case char
            when "*" then {"type" => "bold"}
            when "_" then {"type" => "italic"}
            when "__" then {"type" => "underline"}
            when "`" then {"type" => "code"}
            when "~" then {"type" => "strike"}
            when "||" then {"type" => "spoiler"}
            else raise "Unknown char #{char} @ pos #{offset}!"
            end
          end

          message += piece
          message_len += EntityTools.mb_strlen(piece)

          length_real = message_len - start
          # Trim trailing whitespace from message
          message_bytes = message.bytes
          (message_bytes.length - 1).downto(0) do |x|
            char = message_bytes[x]
            break unless [32, 13, 10].include?(char) # space, \r, \n
            length_real -= 1
          end

          if length_real > 0
            entity["offset"] = start
            entity["length"] = length_real
            entities << entity
          end
        else
          message += piece
          message_len += EntityTools.mb_strlen(piece)
          stack << [char, message_len]
        end
      end

      raise "Found unclosed markdown elements #{stack.map(&:first).join(", ")}" unless stack.empty?

      new(message.strip, entities)
    end

    # Manually convert HTML to a message and a set of entities.
    #
    # @param html [String] HTML text
    # @return [Entities] Object containing message and entities
    def self.from_html(html)
      html = html.gsub(/<br(\s*)?\/?>/i, "\n")
      # Use HTML parser to properly handle boolean attributes like 'expandable'
      doc = Nokogiri::HTML::DocumentFragment.parse("<body>#{html.strip}</body>")
      message = String.new("")
      entities = []
      body = doc.at_css("body")
      parse_node(body, 0, message, entities)
      new(message.strip, entities)
    end

    # Convert a message and a set of entities to HTML.
    #
    # @param allow_telegram_tags [Boolean] Whether to allow telegram-specific tags
    # @return [String] HTML string
    def to_html(allow_telegram_tags = false)
      insertions = {}
      @entities.each do |entity|
        offset = entity["offset"]
        length = entity["length"]
        insertions[offset] ||= ""

        insertions[offset] += case entity["type"]
        when "bold" then "<strong>"
        when "italic" then "<i>"
        when "code" then "<code>"
        when "pre"
          if entity["language"] && !entity["language"].empty?
            "<pre language=\"#{EntityTools.html_escape(entity["language"])}\">"
          else
            "<pre>"
          end
        when "text_url" then "<a href=\"#{EntityTools.html_escape(entity["url"])}\">"
        when "strike" then "<s>"
        when "underline" then "<u>"
        when "blockquote" then "<blockquote>"
        when "url"
          url = EntityTools.html_escape(EntityTools.mb_substr(@message, offset, length))
          "<a href=\"#{url}\">"
        when "email"
          email = EntityTools.html_escape(EntityTools.mb_substr(@message, offset, length))
          "<a href=\"mailto:#{email}\">"
        when "phone"
          phone = EntityTools.html_escape(EntityTools.mb_substr(@message, offset, length))
          "<a href=\"phone:#{phone}\">"
        when "mention"
          mention = EntityTools.html_escape(EntityTools.mb_substr(@message, offset + 1, length - 1))
          "<a href=\"https://t.me/#{mention}\">"
        when "spoiler"
          allow_telegram_tags ? "<tg-spoiler>" : '<span class="tg-spoiler">'
        when "custom_emoji"
          allow_telegram_tags ? "<tg-emoji emoji-id=\"#{entity["custom_emoji_id"]}\">" : ""
        when "mention_name"
          allow_telegram_tags ? "<a href=\"tg://user?id=#{entity["user"]["id"]}\">" : ""
        when "hashtag"
          allow_telegram_tags ? "<tg-hashtag>" : '<span class="tg-hashtag">'
        when "cashtag"
          allow_telegram_tags ? "<tg-cashtag>" : '<span class="tg-cashtag">'
        when "bot_command"
          allow_telegram_tags ? "<tg-bot-command>" : '<span class="tg-bot-command">'
        when "media_timestamp"
          media_timestamp = entity["media_timestamp"]
          if allow_telegram_tags && media_timestamp
            "<tg-media-timestamp timestamp=\"#{EntityTools.html_escape(media_timestamp.to_s)}\">"
          else
            '<span class="tg-media-timestamp">'
          end
        when "bank_card"
          allow_telegram_tags ? "<tg-bank-card-number>" : '<span class="tg-bank-card-number">'
        when "expandable_blockquote"
          allow_telegram_tags ? "<blockquote expandable>" : '<blockquote class="expandable">'
        else ""
        end

        end_offset = offset + length
        insertions[end_offset] ||= ""
        insertions[end_offset] = case entity["type"]
        when "bold" then "</strong>"
        when "italic" then "</i>"
        when "code" then "</code>"
        when "pre" then "</pre>"
        when "text_url", "url", "email", "mention", "phone" then "</a>"
        when "strike" then "</s>"
        when "underline" then "</u>"
        when "blockquote" then "</blockquote>"
        when "spoiler" then allow_telegram_tags ? "</tg-spoiler>" : "</span>"
        when "custom_emoji" then allow_telegram_tags ? "</tg-emoji>" : ""
        when "mention_name" then allow_telegram_tags ? "</a>" : ""
        when "hashtag" then allow_telegram_tags ? "</tg-hashtag>" : "</span>"
        when "cashtag" then allow_telegram_tags ? "</tg-cashtag>" : "</span>"
        when "bot_command" then allow_telegram_tags ? "</tg-bot-command>" : "</span>"
        when "media_timestamp" then allow_telegram_tags ? "</tg-media-timestamp>" : "</span>"
        when "bank_card" then allow_telegram_tags ? "</tg-bank-card-number>" : "</span>"
        when "expandable_blockquote" then "</blockquote>"
        else ""
        end + insertions[end_offset]
      end

      insertions = insertions.sort.to_h
      final = ""
      pos = 0
      insertions.each do |ins_offset, insertion|
        final += EntityTools.html_escape(EntityTools.mb_substr(@message, pos, ins_offset - pos))
        final += insertion
        pos = ins_offset
      end
      final += EntityTools.html_escape(EntityTools.mb_substr(@message, pos))
      final.gsub("\n", "<br>")
    end

    private

    # Parse HTML node recursively
    def self.parse_node(node, offset, message, entities)
      if node.text?
        text = node.text
        message << text
        return EntityTools.mb_strlen(text)
      end

      if node.name == "br"
        message << "\n"
        return 1
      end

      entity = case node.name
      when "s", "strike", "del" then {"type" => "strike"}
      when "u" then {"type" => "underline"}
      when "b", "strong" then {"type" => "bold"}
      when "i", "em" then {"type" => "italic"}
      when "code" then {"type" => "code"}
      when "spoiler", "tg-spoiler" then {"type" => "spoiler"}
      when "pre"
        if node["language"]
          {"type" => "pre", "language" => node["language"]}
        else
          {"type" => "pre"}
        end
      when "span"
        case node["class"]
        when "tg-spoiler"
          {"type" => "spoiler"}
        when "tg-hashtag"
          {"type" => "hashtag"}
        when "tg-cashtag"
          {"type" => "cashtag"}
        when "tg-bot-command"
          {"type" => "bot_command"}
        when "tg-media-timestamp"
          media_timestamp = node["timestamp"] || node["data-timestamp"]
          if media_timestamp
            {"type" => "media_timestamp", "media_timestamp" => media_timestamp.to_i}
          else
            {"type" => "media_timestamp"}
          end
        when "tg-bank-card-number"
          {"type" => "bank_card"}
        end
      when "tg-emoji"
        {"type" => "custom_emoji", "custom_emoji_id" => node["emoji-id"].to_i}
      when "emoji"
        {"type" => "custom_emoji", "custom_emoji_id" => node["id"].to_i}
      when "tg-hashtag"
        {"type" => "hashtag"}
      when "tg-cashtag"
        {"type" => "cashtag"}
      when "tg-bot-command"
        {"type" => "bot_command"}
      when "tg-media-timestamp"
        media_timestamp = node["timestamp"] || node["data-timestamp"]
        if media_timestamp
          {"type" => "media_timestamp", "media_timestamp" => media_timestamp.to_i}
        else
          {"type" => "media_timestamp"}
        end
      when "tg-bank-card-number"
        {"type" => "bank_card"}
      when "blockquote"
        # Check for expandable attribute or class
        if !node["expandable"].nil? || node["class"] == "expandable"
          {"type" => "expandable_blockquote"}
        else
          {"type" => "blockquote"}
        end
      when "a"
        handle_link(node["href"] || "")
      end

      length = 0
      node.children.each do |child|
        length += parse_node(child, offset + length, message, entities)
      end

      if entity
        length_real = length
        # Trim trailing whitespace from message
        message_bytes = message.bytes
        (message_bytes.length - 1).downto(0) do |x|
          char = message_bytes[x]
          break unless [32, 13, 10].include?(char) # space, \r, \n
          length_real -= 1
        end

        if length_real > 0
          entity["offset"] = offset
          entity["length"] = length_real
          entities << entity
        end
      end

      length
    end

    # Handle link href
    def self.handle_link(href)
      if (match = href.match(/^mention:(.+)/)) || (match = href.match(/^tg:\/\/user\?id=(.+)/))
        user_id = match[1].to_i
        {"type" => "mention_name", "user" => {"id" => user_id}}
      elsif (match = href.match(/^emoji:(\d+)$/)) || (match = href.match(/^tg:\/\/emoji\?id=(.+)/))
        emoji_id = match[1].to_i
        {"type" => "custom_emoji", "custom_emoji_id" => emoji_id}
      else
        {"type" => "text_url", "url" => href}
      end
    end
  end
end
