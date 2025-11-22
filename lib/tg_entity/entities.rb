# frozen_string_literal: true

require 'nokogiri'

module TgEntity
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
      message = ''
      message_len = 0
      entities = []
      offset = 0
      stack = []

      while offset < markdown.length
        # Find next special character
        special_chars = '*_~`[]|!\\'
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
        if char == '\\'
          message += piece + (next_char || '')
          message_len += EntityTools.mb_strlen(piece) + 1
          offset += 1 if next_char
          next
        end

        # Handle double characters
        if char == '_' && next_char == '_'
          offset += 1
          char = '__'
        elsif char == '|'
          if next_char == '|'
            offset += 1
            char = '||'
          else
            message += piece + char
            message_len += EntityTools.mb_strlen(piece) + 1
            next
          end
        elsif char == '!'
          if next_char == '['
            offset += 1
            char = ']('
          else
            message += piece + char
            message_len += EntityTools.mb_strlen(piece) + 1
            next
          end
        elsif char == '['
          char = ']('
        elsif char == ']'
          if stack.empty? || stack.last[0] != ']('
            message += piece + char
            message_len += EntityTools.mb_strlen(piece) + 1
            next
          end
          if next_char != '('
            stack.pop
            message += '[' + piece + char
            message_len += EntityTools.mb_strlen(piece) + 2
            next
          end
          offset += 1
          char = ']('
        elsif char == '`'
          message += piece
          message_len += EntityTools.mb_strlen(piece)

          token = '`'
          language = nil
          if next_char == '`' && markdown[offset + 1] == '`'
            token = '```'
            offset += 2
            lang_len = 0
            while offset + lang_len < markdown.length && !["\n", ' '].include?(markdown[offset + lang_len])
              lang_len += 1
            end
            language = markdown[offset, lang_len] if lang_len > 0
            offset += lang_len
            offset += 1 if markdown[offset] == "\n"
          end

          piece = ''
          pos_close = offset
          found = false
          while pos_close < markdown.length
            pos_close = markdown.index(token, pos_close)
            unless pos_close
              found = false
              break
            end

            if pos_close > 0 && markdown[pos_close - 1] == '\\'
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
              'type' => (token == '```' ? 'pre' : 'code'),
              'offset' => start,
              'length' => piece_len
            }
            entity['language'] = language if language
            entities << entity
          end

          offset = pos_close + token.length
          next
        end

        # Handle closing tag
        if !stack.empty? && stack.last[0] == char
          _, start = stack.pop

          if char == ']('
            pos_close = offset
            link = ''
            while pos_close < markdown.length
              pos_close = markdown.index(')', pos_close)
              break unless pos_close

              if pos_close > 0 && markdown[pos_close - 1] == '\\'
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
                     when '*' then { 'type' => 'bold' }
                     when '_' then { 'type' => 'italic' }
                     when '__' then { 'type' => 'underline' }
                     when '`' then { 'type' => 'code' }
                     when '~' then { 'type' => 'strikethrough' }
                     when '||' then { 'type' => 'spoiler' }
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
            entity['offset'] = start
            entity['length'] = length_real
            entities << entity
          end
        else
          message += piece
          message_len += EntityTools.mb_strlen(piece)
          stack << [char, message_len]
        end
      end

      raise "Found unclosed markdown elements #{stack.map(&:first).join(', ')}" unless stack.empty?

      new(message.strip, entities)
    end

    # Manually convert HTML to a message and a set of entities.
    #
    # @param html [String] HTML text
    # @return [Entities] Object containing message and entities
    def self.from_html(html)
      html = html.gsub(/<br(\s*)?\/?>/i, "\n")
      doc = Nokogiri::XML::Document.parse("<body>#{html.strip}</body>")
      message = String.new('')
      entities = []
      body = doc.at_css('body')
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
        offset = entity['offset']
        length = entity['length']
        insertions[offset] ||= ''

        insertions[offset] += case entity['type']
                              when 'bold' then '<b>'
                              when 'italic' then '<i>'
                              when 'code' then '<code>'
                              when 'pre'
                                if entity['language'] && !entity['language'].empty?
                                  "<pre language=\"#{EntityTools.html_escape(entity['language'])}\">"
                                else
                                  '<pre>'
                                end
                              when 'text_link' then "<a href=\"#{EntityTools.html_escape(entity['url'])}\">"
                              when 'strikethrough' then '<s>'
                              when 'underline' then '<u>'
                              when 'block_quote' then '<blockquote>'
                              when 'url'
                                url = EntityTools.html_escape(EntityTools.mb_substr(@message, offset, length))
                                "<a href=\"#{url}\">"
                              when 'email'
                                email = EntityTools.html_escape(EntityTools.mb_substr(@message, offset, length))
                                "<a href=\"mailto:#{email}\">"
                              when 'phone'
                                phone = EntityTools.html_escape(EntityTools.mb_substr(@message, offset, length))
                                "<a href=\"phone:#{phone}\">"
                              when 'mention'
                                mention = EntityTools.html_escape(EntityTools.mb_substr(@message, offset + 1, length - 1))
                                "<a href=\"https://t.me/#{mention}\">"
                              when 'spoiler'
                                allow_telegram_tags ? '<tg-spoiler>' : '<span class="tg-spoiler">'
                              when 'custom_emoji'
                                allow_telegram_tags ? "<tg-emoji emoji-id=\"#{entity['custom_emoji_id']}\">" : ''
                              when 'text_mention'
                                allow_telegram_tags ? "<a href=\"tg://user?id=#{entity['user']['id']}\">" : ''
                              else ''
                              end

        end_offset = offset + length
        insertions[end_offset] ||= ''
        insertions[end_offset] = case entity['type']
                                  when 'bold' then '</b>'
                                  when 'italic' then '</i>'
                                  when 'code' then '</code>'
                                  when 'pre' then '</pre>'
                                  when 'text_link', 'url', 'email', 'mention', 'phone' then '</a>'
                                  when 'strikethrough' then '</s>'
                                  when 'underline' then '</u>'
                                  when 'block_quote' then '</blockquote>'
                                  when 'spoiler' then allow_telegram_tags ? '</tg-spoiler>' : '</span>'
                                  when 'custom_emoji' then allow_telegram_tags ? '</tg-emoji>' : ''
                                  when 'text_mention' then allow_telegram_tags ? '</a>' : ''
                                  else ''
                                  end + insertions[end_offset]
      end

      insertions = insertions.sort.to_h
      final = ''
      pos = 0
      insertions.each do |ins_offset, insertion|
        final += EntityTools.html_escape(EntityTools.mb_substr(@message, pos, ins_offset - pos))
        final += insertion
        pos = ins_offset
      end
      final += EntityTools.html_escape(EntityTools.mb_substr(@message, pos))
      final.gsub("\n", '<br>')
    end

    # Convert a message and a set of entities to MarkdownV2.
    #
    # @return [String] Markdown string
    def to_markdown
      # Sort entities by offset, then by length (longer first for nested)
      sorted_entities = @entities.sort_by { |e| [e['offset'], -e['length']] }
      insertions = {}

      sorted_entities.each do |entity|
        offset = entity['offset']
        length = entity['length']
        insertions[offset] ||= ''
        insertions[offset + length] ||= ''

        case entity['type']
        when 'bold'
          insertions[offset] += '*'
          insertions[offset + length] = '*' + insertions[offset + length]
        when 'italic'
          insertions[offset] += '_'
          insertions[offset + length] = '_' + insertions[offset + length]
        when 'underline'
          insertions[offset] += '__'
          insertions[offset + length] = '__' + insertions[offset + length]
        when 'strikethrough'
          insertions[offset] += '~'
          insertions[offset + length] = '~' + insertions[offset + length]
        when 'code'
          insertions[offset] += '`'
          insertions[offset + length] = '`' + insertions[offset + length]
        when 'pre', 'pre_code'
          language = entity['language'] || ''
          insertions[offset] = "```#{language}\n" + insertions[offset]
          insertions[offset + length] = "\n```" + insertions[offset + length]
        when 'spoiler'
          insertions[offset] += '||'
          insertions[offset + length] = '||' + insertions[offset + length]
        when 'text_link'
          url = EntityTools.markdown_url_escape(entity['url'])
          insertions[offset] = '[' + insertions[offset]
          insertions[offset + length] = "](#{url})" + insertions[offset + length]
        when 'custom_emoji'
          insertions[offset] = '![' + insertions[offset]
          insertions[offset + length] = "](tg://emoji?id=#{entity['custom_emoji_id']})" + insertions[offset + length]
        end
      end

      # Build markdown string
      result = ''
      pos = 0
      insertions.sort.each do |ins_offset, insertion|
        # Escape text between positions
        text_segment = EntityTools.mb_substr(@message, pos, ins_offset - pos)
        result += escape_text_for_markdown(text_segment, pos, insertions)
        result += insertion
        pos = ins_offset
      end
      result += escape_text_for_markdown(EntityTools.mb_substr(@message, pos), pos, insertions)
      result
    end

    private

    # Parse HTML node recursively
    def self.parse_node(node, offset, message, entities)
      if node.text?
        text = node.text
        message << text
        return EntityTools.mb_strlen(text)
      end

      if node.name == 'br'
        message << "\n"
        return 1
      end

      entity = case node.name
               when 's', 'strike', 'del' then { 'type' => 'strikethrough' }
               when 'u' then { 'type' => 'underline' }
               when 'blockquote' then { 'type' => 'block_quote' }
               when 'b', 'strong' then { 'type' => 'bold' }
               when 'i', 'em' then { 'type' => 'italic' }
               when 'code' then { 'type' => 'code' }
               when 'spoiler', 'tg-spoiler' then { 'type' => 'spoiler' }
               when 'pre'
                 if node['language']
                   { 'type' => 'pre', 'language' => node['language'] }
                 else
                   { 'type' => 'pre' }
                 end
               when 'span'
                 if node['class'] == 'tg-spoiler'
                   { 'type' => 'spoiler' }
                 else
                   nil
                 end
               when 'tg-emoji'
                 { 'type' => 'custom_emoji', 'custom_emoji_id' => node['emoji-id'].to_i }
               when 'emoji'
                 { 'type' => 'custom_emoji', 'custom_emoji_id' => node['id'].to_i }
               when 'a'
                 handle_link(node['href'] || '')
               else
                 nil
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
          entity['offset'] = offset
          entity['length'] = length_real
          entities << entity
        end
      end

      length
    end

    # Handle link href
    def self.handle_link(href)
      if (match = href.match(/^mention:(.+)/)) || (match = href.match(/^tg:\/\/user\?id=(.+)/))
        user_id = match[1].to_i
        { 'type' => 'text_mention', 'user' => { 'id' => user_id } }
      elsif (match = href.match(/^emoji:(\d+)$/)) || (match = href.match(/^tg:\/\/emoji\?id=(.+)/))
        emoji_id = match[1].to_i
        { 'type' => 'custom_emoji', 'custom_emoji_id' => emoji_id }
      else
        { 'type' => 'text_link', 'url' => href }
      end
    end

    # Escape text for markdown
    # We need to escape special characters that are not part of entities
    def escape_text_for_markdown(text, current_offset, insertions)
      # For now, escape all special characters
      # In a more sophisticated implementation, we'd track which characters
      # are already part of entity markers
      EntityTools.markdown_escape(text)
    end
  end
end
