# frozen_string_literal: true

require "test_helper"
require "json"

class TestEntities < Minitest::Test
  def test_from_markdown_bold
    entities = TelegramEntities.from_markdown("*test*")
    assert_equal "test", entities.message
    assert_equal 1, entities.entities.length
    assert_equal "bold", entities.entities[0]["type"]
    assert_equal 0, entities.entities[0]["offset"]
    assert_equal 4, entities.entities[0]["length"]
  end

  def test_from_markdown_italic
    entities = TelegramEntities.from_markdown("_test_")
    assert_equal "test", entities.message
    assert_equal 1, entities.entities.length
    assert_equal "italic", entities.entities[0]["type"]
  end

  def test_from_markdown_underline
    entities = TelegramEntities.from_markdown("__test__")
    assert_equal "test", entities.message
    assert_equal 1, entities.entities.length
    assert_equal "underline", entities.entities[0]["type"]
  end

  def test_from_markdown_strike
    entities = TelegramEntities.from_markdown("~test~")
    assert_equal "test", entities.message
    assert_equal 1, entities.entities.length
    assert_equal "strike", entities.entities[0]["type"]
  end

  def test_from_markdown_code
    entities = TelegramEntities.from_markdown("`test`")
    assert_equal "test", entities.message
    assert_equal 1, entities.entities.length
    assert_equal "code", entities.entities[0]["type"]
  end

  def test_from_markdown_spoiler
    entities = TelegramEntities.from_markdown("||test||")
    assert_equal "test", entities.message
    assert_equal 1, entities.entities.length
    assert_equal "spoiler", entities.entities[0]["type"]
  end

  def test_from_markdown_pre
    entities = TelegramEntities.from_markdown("```php\ncode\n```")
    assert_equal "code", entities.message
    assert_equal 1, entities.entities.length
    assert_equal "pre", entities.entities[0]["type"]
    assert_equal "php", entities.entities[0]["language"]
  end

  def test_from_markdown_nested
    entities = TelegramEntities.from_markdown("*bold _italic_ bold*")
    assert_equal "bold italic bold", entities.message
    assert_equal 2, entities.entities.length
    # Italic should be first (inner)
    assert_equal "italic", entities.entities[0]["type"]
    assert_equal "bold", entities.entities[1]["type"]
  end

  def test_from_markdown_link
    entities = TelegramEntities.from_markdown("[text](https://example.com)")
    assert_equal "text", entities.message
    assert_equal 1, entities.entities.length
    assert_equal "text_url", entities.entities[0]["type"]
    assert_equal "https://example.com", entities.entities[0]["url"]
  end

  def test_from_markdown_escape
    entities = TelegramEntities.from_markdown('\\*test\\*')
    assert_equal "*test*", entities.message
    assert_equal 0, entities.entities.length
  end

  def test_from_markdown_unclosed_tag
    assert_raises(RuntimeError) do
      TelegramEntities.from_markdown("*test")
    end
  end

  def test_from_markdown_unclosed_link
    assert_raises(RuntimeError) do
      TelegramEntities.from_markdown("[test](https://google.com")
    end
  end

  def test_from_markdown_unclosed_code
    assert_raises(RuntimeError) do
      TelegramEntities.from_markdown("```")
    end
  end

  def test_from_html_bold
    entities = TelegramEntities.from_html("<b>test</b>")
    assert_equal "test", entities.message
    assert_equal 1, entities.entities.length
    assert_equal "bold", entities.entities[0]["type"]
  end

  def test_from_html_italic
    entities = TelegramEntities.from_html("<i>test</i>")
    assert_equal "test", entities.message
    assert_equal 1, entities.entities.length
    assert_equal "italic", entities.entities[0]["type"]
  end

  def test_from_html_underline
    entities = TelegramEntities.from_html("<u>test</u>")
    assert_equal "test", entities.message
    assert_equal 1, entities.entities.length
    assert_equal "underline", entities.entities[0]["type"]
  end

  def test_from_html_strike
    entities = TelegramEntities.from_html("<s>test</s>")
    assert_equal "test", entities.message
    assert_equal 1, entities.entities.length
    assert_equal "strike", entities.entities[0]["type"]
  end

  def test_from_html_code
    entities = TelegramEntities.from_html("<code>test</code>")
    assert_equal "test", entities.message
    assert_equal 1, entities.entities.length
    assert_equal "code", entities.entities[0]["type"]
  end

  def test_from_html_pre
    entities = TelegramEntities.from_html('<pre language="php">test</pre>')
    assert_equal "test", entities.message
    assert_equal 1, entities.entities.length
    assert_equal "pre", entities.entities[0]["type"]
    assert_equal "php", entities.entities[0]["language"]
  end

  def test_from_html_link
    entities = TelegramEntities.from_html('<a href="https://example.com">test</a>')
    assert_equal "test", entities.message
    assert_equal 1, entities.entities.length
    assert_equal "text_url", entities.entities[0]["type"]
    assert_equal "https://example.com", entities.entities[0]["url"]
  end

  def test_from_html_br
    entities = TelegramEntities.from_html("<b>test</b><br>test")
    assert_equal "test\ntest", entities.message
  end

  def test_from_html_br_self_closing
    entities = TelegramEntities.from_html("<b>test</b><br/>test")
    assert_equal "test\ntest", entities.message
  end

  def test_from_html_spoiler
    entities = TelegramEntities.from_html("<tg-spoiler>test</tg-spoiler>")
    assert_equal "test", entities.message
    assert_equal 1, entities.entities.length
    assert_equal "spoiler", entities.entities[0]["type"]
  end

  def test_from_html_custom_emoji
    entities = TelegramEntities.from_html('<tg-emoji emoji-id="12345">test</tg-emoji>')
    assert_equal "test", entities.message
    assert_equal 1, entities.entities.length
    assert_equal "custom_emoji", entities.entities[0]["type"]
    assert_equal 12345, entities.entities[0]["custom_emoji_id"]
  end

  def test_from_html_mention_name
    entities = TelegramEntities.from_html('<a href="tg://user?id=12345">test</a>')
    assert_equal "test", entities.message
    assert_equal 1, entities.entities.length
    assert_equal "mention_name", entities.entities[0]["type"]
    assert_equal 12345, entities.entities[0]["user"]["id"]
  end

  def test_from_html_nested
    entities = TelegramEntities.from_html("<b>bold <i>italic</i> bold</b>")
    assert_equal "bold italic bold", entities.message
    assert_equal 2, entities.entities.length
    assert_equal "italic", entities.entities[0]["type"]
    assert_equal "bold", entities.entities[1]["type"]
  end

  def test_to_html_bold
    entities = TelegramEntities.new("test", [{"type" => "bold", "offset" => 0, "length" => 4}])
    assert_equal "<strong>test</strong>", entities.to_html
  end

  def test_to_html_italic
    entities = TelegramEntities.new("test", [{"type" => "italic", "offset" => 0, "length" => 4}])
    assert_equal "<i>test</i>", entities.to_html
  end

  def test_to_html_code
    entities = TelegramEntities.new("test", [{"type" => "code", "offset" => 0, "length" => 4}])
    assert_equal "<code>test</code>", entities.to_html
  end

  def test_to_html_pre
    entities = TelegramEntities.new("test", [{"type" => "pre", "offset" => 0, "length" => 4, "language" => "php"}])
    assert_equal '<pre language="php">test</pre>', entities.to_html
  end

  def test_to_html_text_url
    entities = TelegramEntities.new("test", [{"type" => "text_url", "offset" => 0, "length" => 4, "url" => "https://example.com"}])
    assert_equal '<a href="https://example.com">test</a>', entities.to_html
  end

  def test_to_html_spoiler
    entities = TelegramEntities.new("test", [{"type" => "spoiler", "offset" => 0, "length" => 4}])
    assert_equal '<span class="tg-spoiler">test</span>', entities.to_html
    assert_equal "<tg-spoiler>test</tg-spoiler>", entities.to_html(true)
  end

  def test_to_html_custom_emoji
    entities = TelegramEntities.new("test", [{"type" => "custom_emoji", "offset" => 0, "length" => 4, "custom_emoji_id" => 12345}])
    assert_equal "test", entities.to_html
    assert_equal '<tg-emoji emoji-id="12345">test</tg-emoji>', entities.to_html(true)
  end

  def test_to_html_nested
    entities = TelegramEntities.new("test", [
      {"type" => "italic", "offset" => 0, "length" => 4},
      {"type" => "bold", "offset" => 0, "length" => 4}
    ])
    html = entities.to_html
    assert_match(/<strong>/, html)
    assert_match(/<i>/, html)
  end

  def test_to_html_escape
    entities = TelegramEntities.new("<b>test</b>", [])
    assert_equal "&lt;b&gt;test&lt;/b&gt;", entities.to_html
  end

  def test_to_html_hashtag
    entities = TelegramEntities.new("#test", [{"type" => "hashtag", "offset" => 0, "length" => 5}])
    assert_equal '<span class="tg-hashtag">#test</span>', entities.to_html
    assert_equal "<tg-hashtag>#test</tg-hashtag>", entities.to_html(true)
  end

  def test_to_html_cashtag
    entities = TelegramEntities.new("$USD", [{"type" => "cashtag", "offset" => 0, "length" => 4}])
    assert_equal '<span class="tg-cashtag">$USD</span>', entities.to_html
    assert_equal "<tg-cashtag>$USD</tg-cashtag>", entities.to_html(true)
  end

  def test_to_html_bot_command
    entities = TelegramEntities.new("/start", [{"type" => "bot_command", "offset" => 0, "length" => 6}])
    assert_equal '<span class="tg-bot-command">/start</span>', entities.to_html
    assert_equal "<tg-bot-command>/start</tg-bot-command>", entities.to_html(true)
  end

  def test_to_html_media_timestamp
    entities = TelegramEntities.new("0:30", [{"type" => "media_timestamp", "offset" => 0, "length" => 4, "media_timestamp" => 30}])
    assert_equal '<span class="tg-media-timestamp">0:30</span>', entities.to_html
    assert_equal '<tg-media-timestamp timestamp="30">0:30</tg-media-timestamp>', entities.to_html(true)
  end

  def test_to_html_bank_card
    entities = TelegramEntities.new("1234 5678 9012 3456", [{"type" => "bank_card", "offset" => 0, "length" => 19}])
    assert_equal '<span class="tg-bank-card-number">1234 5678 9012 3456</span>', entities.to_html
    assert_equal "<tg-bank-card-number>1234 5678 9012 3456</tg-bank-card-number>", entities.to_html(true)
  end

  def test_to_html_expandable_blockquote
    entities = TelegramEntities.new("quote", [{"type" => "expandable_blockquote", "offset" => 0, "length" => 5}])
    assert_equal '<blockquote class="expandable">quote</blockquote>', entities.to_html
    assert_equal "<blockquote expandable>quote</blockquote>", entities.to_html(true)
  end

  def test_from_html_hashtag
    entities = TelegramEntities.from_html("<tg-hashtag>#test</tg-hashtag>")
    assert_equal "#test", entities.message
    assert_equal 1, entities.entities.length
    assert_equal "hashtag", entities.entities[0]["type"]
  end

  def test_from_html_hashtag_span
    entities = TelegramEntities.from_html('<span class="tg-hashtag">#test</span>')
    assert_equal "#test", entities.message
    assert_equal 1, entities.entities.length
    assert_equal "hashtag", entities.entities[0]["type"]
  end

  def test_from_html_cashtag
    entities = TelegramEntities.from_html("<tg-cashtag>$USD</tg-cashtag>")
    assert_equal "$USD", entities.message
    assert_equal 1, entities.entities.length
    assert_equal "cashtag", entities.entities[0]["type"]
  end

  def test_from_html_cashtag_span
    entities = TelegramEntities.from_html('<span class="tg-cashtag">$USD</span>')
    assert_equal "$USD", entities.message
    assert_equal 1, entities.entities.length
    assert_equal "cashtag", entities.entities[0]["type"]
  end

  def test_from_html_bot_command
    entities = TelegramEntities.from_html("<tg-bot-command>/start</tg-bot-command>")
    assert_equal "/start", entities.message
    assert_equal 1, entities.entities.length
    assert_equal "bot_command", entities.entities[0]["type"]
  end

  def test_from_html_bot_command_span
    entities = TelegramEntities.from_html('<span class="tg-bot-command">/start</span>')
    assert_equal "/start", entities.message
    assert_equal 1, entities.entities.length
    assert_equal "bot_command", entities.entities[0]["type"]
  end

  def test_from_html_media_timestamp
    entities = TelegramEntities.from_html('<tg-media-timestamp timestamp="30">0:30</tg-media-timestamp>')
    assert_equal "0:30", entities.message
    assert_equal 1, entities.entities.length
    assert_equal "media_timestamp", entities.entities[0]["type"]
    assert_equal 30, entities.entities[0]["media_timestamp"]
  end

  def test_from_html_media_timestamp_span
    entities = TelegramEntities.from_html('<span class="tg-media-timestamp" data-timestamp="30">0:30</span>')
    assert_equal "0:30", entities.message
    assert_equal 1, entities.entities.length
    assert_equal "media_timestamp", entities.entities[0]["type"]
    assert_equal 30, entities.entities[0]["media_timestamp"]
  end

  def test_from_html_bank_card
    entities = TelegramEntities.from_html("<tg-bank-card-number>1234 5678 9012 3456</tg-bank-card-number>")
    assert_equal "1234 5678 9012 3456", entities.message
    assert_equal 1, entities.entities.length
    assert_equal "bank_card", entities.entities[0]["type"]
  end

  def test_from_html_bank_card_span
    entities = TelegramEntities.from_html('<span class="tg-bank-card-number">1234 5678 9012 3456</span>')
    assert_equal "1234 5678 9012 3456", entities.message
    assert_equal 1, entities.entities.length
    assert_equal "bank_card", entities.entities[0]["type"]
  end

  def test_from_html_expandable_blockquote
    entities = TelegramEntities.from_html("<blockquote expandable>quote</blockquote>")
    assert_equal "quote", entities.message
    assert_equal 1, entities.entities.length
    assert_equal "expandable_blockquote", entities.entities[0]["type"]
  end

  def test_from_html_expandable_blockquote_class
    entities = TelegramEntities.from_html('<blockquote class="expandable">quote</blockquote>')
    assert_equal "quote", entities.message
    assert_equal 1, entities.entities.length
    assert_equal "expandable_blockquote", entities.entities[0]["type"]
  end

  def test_utf16_emoji
    entities = TelegramEntities.from_markdown("*👍*")
    assert_equal "👍", entities.message
    assert_equal 1, entities.entities.length
    assert_equal 0, entities.entities[0]["offset"]
    assert_equal 2, entities.entities[0]["length"] # Emoji is 2 UTF-16 code units
  end

  def test_utf16_flag
    entities = TelegramEntities.from_markdown("*🇺🇦*")
    assert_equal "🇺🇦", entities.message
    assert_equal 1, entities.entities.length
    assert_equal 0, entities.entities[0]["offset"]
    assert_equal 4, entities.entities[0]["length"] # Flag is 4 UTF-16 code units
  end

  def test_round_trip_markdown_html
    original = "*bold _italic_ bold*"
    entities = TelegramEntities.from_markdown(original)
    html = entities.to_html
    entities2 = TelegramEntities.from_html(html)
    assert_equal entities.message, entities2.message
    # Entities might be slightly different due to whitespace trimming, but message should match
  end

  def test_real_example
    input_data = JSON.parse(File.read("#{__dir__}/fixtures/example_1/data.json"))
    expected_html = File.read("#{__dir__}/fixtures/example_1/message.html")
    entities = TelegramEntities.new(input_data[0], input_data[1])
    assert_equal expected_html, entities.to_html
  end

  def test_to_bot_html_hashtag
    entities = TelegramEntities.new("#test", [{"type" => "hashtag", "offset" => 0, "length" => 5}])
    # Hashtags should be sent without wrapper (automatically processed by bot)
    assert_equal "#test", entities.to_bot_html
  end

  def test_to_bot_html_cashtag
    entities = TelegramEntities.new("$USD", [{"type" => "cashtag", "offset" => 0, "length" => 4}])
    # Cashtags should be sent without wrapper (automatically processed by bot)
    assert_equal "$USD", entities.to_bot_html
  end

  def test_to_bot_html_bot_command
    entities = TelegramEntities.new("/start", [{"type" => "bot_command", "offset" => 0, "length" => 6}])
    # Bot commands should be sent without wrapper (automatically processed by bot)
    assert_equal "/start", entities.to_bot_html
  end

  def test_to_bot_html_media_timestamp
    entities = TelegramEntities.new("0:30", [{"type" => "media_timestamp", "offset" => 0, "length" => 4, "media_timestamp" => 30}])
    # Media timestamps should be sent without wrapper (automatically processed by bot)
    assert_equal "0:30", entities.to_bot_html
  end

  def test_to_bot_html_bank_card
    entities = TelegramEntities.new("1234 5678 9012 3456", [{"type" => "bank_card", "offset" => 0, "length" => 19}])
    # Bank card numbers should be sent without wrapper (automatically processed by bot)
    assert_equal "1234 5678 9012 3456", entities.to_bot_html
  end

  def test_to_bot_html_spoiler
    entities = TelegramEntities.new("spoiler text", [{"type" => "spoiler", "offset" => 0, "length" => 13}])
    # Spoilers should keep tg-spoiler tags
    assert_equal "<tg-spoiler>spoiler text</tg-spoiler>", entities.to_bot_html
  end

  def test_to_bot_html_custom_emoji
    entities = TelegramEntities.new("😀", [{"type" => "custom_emoji", "offset" => 0, "length" => 2, "custom_emoji_id" => 12345}])
    # Custom emojis should keep tg-emoji tags
    assert_equal '<tg-emoji emoji-id="12345">😀</tg-emoji>', entities.to_bot_html
  end

  def test_to_bot_html_br_replacement
    entities = TelegramEntities.new("Line 1\nLine 2", [])
    html = entities.to_html(true)
    # to_html converts \n to <br>
    assert_match(/<br>/, html)
    # to_bot_html should convert <br> back to \n
    bot_html = entities.to_bot_html
    assert_match(/\n/, bot_html)
    refute_match(/<br/, bot_html)
  end

  def test_to_bot_html_mixed_content
    entities = TelegramEntities.new("Check #hashtag and /start command", [
      {"type" => "hashtag", "offset" => 6, "length" => 8},
      {"type" => "bot_command", "offset" => 19, "length" => 7}
    ])
    # Both hashtag and bot_command should be without wrappers
    result = entities.to_bot_html
    assert_equal "Check #hashtag and /start command", result
    refute_match(/<tg-hashtag>/, result)
    refute_match(/<tg-bot-command>/, result)
  end

  def test_to_bot_html_escapes_special_characters
    # Test that <, >, &, " are properly escaped
    entities = TelegramEntities.new('Text with < > & " symbols', [])
    result = entities.to_bot_html
    assert_match(/&lt;/, result)
    assert_match(/&gt;/, result)
    assert_match(/&amp;/, result)
    assert_match(/&quot;/, result)
    # Check that there are no unescaped <, >, &, " symbols (except in HTML entities)
    # Remove all HTML entities and check that no raw symbols remain
    without_entities = result.gsub(/&(?:lt|gt|amp|quot|#\d+);/, '')
    refute_match(/</, without_entities, "Should not contain unescaped <")
    refute_match(/>/, without_entities, "Should not contain unescaped >")
    refute_match(/&/, without_entities, "Should not contain unescaped &")
    refute_match(/"/, without_entities, "Should not contain unescaped \"")
  end

  def test_to_bot_html_supports_named_entities
    # Test that named HTML entities are supported when parsing HTML
    entities = TelegramEntities.from_html('Text with &lt; &gt; &amp; &quot; entities')
    result = entities.to_bot_html
    # Nokogiri decodes entities, so they should be re-escaped in output
    assert_match(/&lt;/, result)
    assert_match(/&gt;/, result)
    assert_match(/&amp;/, result)
    assert_match(/&quot;/, result)
  end

  def test_to_bot_html_supports_numeric_entities
    # Test that numeric HTML entities are supported when parsing HTML
    entities = TelegramEntities.from_html('Text with &#60; &#62; &#38; &#34; entities')
    result = entities.to_bot_html
    # Nokogiri decodes numeric entities, so they should be re-escaped in output
    assert_match(/&lt;/, result)
    assert_match(/&gt;/, result)
    assert_match(/&amp;/, result)
    assert_match(/&quot;/, result)
  end

  def test_to_bot_html_escapes_in_attributes
    # Test that attributes are properly escaped
    entities = TelegramEntities.new("test", [{
      "type" => "text_url",
      "offset" => 0,
      "length" => 4,
      "url" => 'https://example.com?q=test&param=value'
    }])
    result = entities.to_bot_html
    # URL should be properly escaped in href attribute
    assert_match(/&amp;/, result)
    assert_match(/href=/, result)
  end

  def test_to_bot_html_escapes_in_code_blocks
    # Test that code blocks properly escape HTML
    entities = TelegramEntities.new('if (x < 5 && y > 10) {', [{
      "type" => "code",
      "offset" => 0,
      "length" => 25
    }])
    result = entities.to_bot_html
    # Code content should be properly escaped
    assert_match(/&lt;/, result)
    assert_match(/&gt;/, result)
    assert_match(/&amp;/, result)
  end
end
