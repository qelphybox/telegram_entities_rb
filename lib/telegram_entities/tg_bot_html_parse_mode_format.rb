# frozen_string_literal: true

module TelegramEntities
  # doc: https://core.telegram.org/bots/api#html-style
  module TgBotHtmlParseModeFormat
    # Format HTML for Telegram Bot API parse_mode: 'HTML'
    #
    # According to Telegram Bot API documentation:
    # - All <br>, <br/> tags are replaced with \n
    # - Hashtags, cashtags, bot commands, media timestamps, and bank card numbers
    #   are sent without wrappers (they are automatically processed by the bot)
    # - tg-spoiler and tg-emoji tags are left as-is
    # - All <, >, &, " symbols that are not part of a tag or HTML entity
    #   are replaced with corresponding HTML entities (&lt;, &gt;, &amp;, &quot;)
    # - All numerical HTML entities are supported (e.g., &#60;, &#x3C;)
    # - Named HTML entities are supported: &lt;, &gt;, &amp;, &quot;
    #
    # @return [String] Formatted HTML text for Telegram Bot API
    def to_bot_html
      html = to_html(true)

      # Replace all <br> and <br/> tags with \n
      html = html.gsub(/<br\s*\/?>/i, "\n")

      # Remove wrappers for hashtags, cashtags, bot commands, media timestamps, and bank card numbers
      # These are automatically processed by Telegram, so we just extract the text content
      html = html.gsub(/<tg-hashtag>(.*?)<\/tg-hashtag>/i) { |_| $1 }
      html = html.gsub(/<tg-cashtag>(.*?)<\/tg-cashtag>/i) { |_| $1 }
      html = html.gsub(/<tg-bot-command>(.*?)<\/tg-bot-command>/i) { |_| $1 }
      html = html.gsub(/<tg-media-timestamp[^>]*>(.*?)<\/tg-media-timestamp>/i) { |_| $1 }
      html.gsub(/<tg-bank-card-number>(.*?)<\/tg-bank-card-number>/i) { |_| $1 }
    end
  end
end
