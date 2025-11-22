# frozen_string_literal: true

require "cgi"

module TelegramEntities
  # Telegram UTF-16 styled text entity tools.
  module EntityTools
    # Get length of string in UTF-16 code points.
    #
    # @param text [String] Text
    # @return [Integer] Length in UTF-16 code units
    def self.mb_strlen(text)
      # Convert to UTF-16 and count code units
      # Each character in UTF-16 is 2 bytes, but surrogate pairs (for emojis) take 4 bytes (2 code units)
      utf16 = text.encode("UTF-16BE")
      utf16.bytesize / 2
    end

    # Telegram UTF-16 multibyte substring.
    #
    # @param text [String] Text to substring
    # @param offset [Integer] Offset in UTF-16 code units
    # @param length [Integer, nil] Length in UTF-16 code units
    # @return [String] Substring
    def self.mb_substr(text, offset, length = nil)
      utf16 = text.encode("UTF-16BE")
      byte_offset = offset * 2
      byte_length = length ? length * 2 : nil
      substring = if byte_length
        utf16.byteslice(byte_offset, byte_length)
      else
        utf16.byteslice(byte_offset..-1)
      end
      substring&.force_encoding("UTF-16BE")&.encode("UTF-8") || ""
    end

    # Telegram UTF-16 multibyte split.
    #
    # @param text [String] Text
    # @param length [Integer] Length in UTF-16 code units
    # @return [Array<String>] Array of strings
    def self.mb_str_split(text, length)
      utf16 = text.encode("UTF-16BE")
      byte_length = length * 2
      result = []
      offset = 0
      while offset < utf16.bytesize
        chunk = utf16.byteslice(offset, byte_length)
        break if chunk.nil?
        chunk.force_encoding("UTF-16BE")
        result << chunk.encode("UTF-8")
        offset += byte_length
      end
      result
    end

    # Telegram UTF-16 multibyte subreplace.
    #
    # @param string [String] Text
    # @param replace [String] Replacement
    # @param offset [Integer] Offset in UTF-16 code units
    # @param length [Integer, nil] Length in UTF-16 code units
    # @return [String] Result string
    def self.mb_substr_replace(string, replace, offset, length = nil)
      utf16_string = string.encode("UTF-16BE")
      utf16_replace = replace.encode("UTF-16BE")
      byte_offset = offset * 2
      byte_length = length ? length * 2 : nil

      result = if byte_length
        utf16_string.byteslice(0, byte_offset) +
          utf16_replace +
          utf16_string.byteslice(byte_offset + byte_length..-1)
      else
        utf16_string.byteslice(0, byte_offset) + utf16_replace
      end

      result.force_encoding("UTF-16BE").encode("UTF-8")
    end

    # Escape string for this library's HTML entity converter.
    #
    # @param what [String] String to escape
    # @return [String] Escaped string
    def self.html_escape(what)
      CGI.escapeHTML(what)
    end

    # Escape string for markdown.
    #
    # @param what [String] String to escape
    # @return [String] Escaped string
    def self.markdown_escape(what)
      what.gsub(/[\\_*\[\]()~`>#+\-=|{}.!]/) { |char| "\\#{char}" }
    end

    # Escape string for markdown codeblock.
    #
    # @param what [String] String to escape
    # @return [String] Escaped string
    def self.markdown_codeblock_escape(what)
      what.gsub("```") { "\\```" }
    end

    # Escape string for markdown code section.
    #
    # @param what [String] String to escape
    # @return [String] Escaped string
    def self.markdown_code_escape(what)
      what.gsub("`") { "\\`" }
    end

    # Escape string for URL.
    #
    # @param what [String] String to escape
    # @return [String] Escaped string
    def self.markdown_url_escape(what)
      what.gsub(")", '\\)')
    end
  end
end
