# frozen_string_literal: true

require "test_helper"

class TestEntities < Minitest::Test
  def test_from_markdown_bold
    entities = TgEntity::Entities.from_markdown('*test*')
    assert_equal 'test', entities.message
    assert_equal 1, entities.entities.length
    assert_equal 'bold', entities.entities[0]['type']
    assert_equal 0, entities.entities[0]['offset']
    assert_equal 4, entities.entities[0]['length']
  end

  def test_from_markdown_italic
    entities = TgEntity::Entities.from_markdown('_test_')
    assert_equal 'test', entities.message
    assert_equal 1, entities.entities.length
    assert_equal 'italic', entities.entities[0]['type']
  end

  def test_from_markdown_underline
    entities = TgEntity::Entities.from_markdown('__test__')
    assert_equal 'test', entities.message
    assert_equal 1, entities.entities.length
    assert_equal 'underline', entities.entities[0]['type']
  end

  def test_from_markdown_strikethrough
    entities = TgEntity::Entities.from_markdown('~test~')
    assert_equal 'test', entities.message
    assert_equal 1, entities.entities.length
    assert_equal 'strikethrough', entities.entities[0]['type']
  end

  def test_from_markdown_code
    entities = TgEntity::Entities.from_markdown('`test`')
    assert_equal 'test', entities.message
    assert_equal 1, entities.entities.length
    assert_equal 'code', entities.entities[0]['type']
  end

  def test_from_markdown_spoiler
    entities = TgEntity::Entities.from_markdown('||test||')
    assert_equal 'test', entities.message
    assert_equal 1, entities.entities.length
    assert_equal 'spoiler', entities.entities[0]['type']
  end

  def test_from_markdown_pre
    entities = TgEntity::Entities.from_markdown("```php\ncode\n```")
    assert_equal "code", entities.message
    assert_equal 1, entities.entities.length
    assert_equal 'pre', entities.entities[0]['type']
    assert_equal 'php', entities.entities[0]['language']
  end

  def test_from_markdown_nested
    entities = TgEntity::Entities.from_markdown('*bold _italic_ bold*')
    assert_equal 'bold italic bold', entities.message
    assert_equal 2, entities.entities.length
    # Italic should be first (inner)
    assert_equal 'italic', entities.entities[0]['type']
    assert_equal 'bold', entities.entities[1]['type']
  end

  def test_from_markdown_link
    entities = TgEntity::Entities.from_markdown('[text](https://example.com)')
    assert_equal 'text', entities.message
    assert_equal 1, entities.entities.length
    assert_equal 'text_link', entities.entities[0]['type']
    assert_equal 'https://example.com', entities.entities[0]['url']
  end

  def test_from_markdown_escape
    entities = TgEntity::Entities.from_markdown('\\*test\\*')
    assert_equal '*test*', entities.message
    assert_equal 0, entities.entities.length
  end

  def test_from_markdown_unclosed_tag
    assert_raises(RuntimeError) do
      TgEntity::Entities.from_markdown('*test')
    end
  end

  def test_from_markdown_unclosed_link
    assert_raises(RuntimeError) do
      TgEntity::Entities.from_markdown('[test](https://google.com')
    end
  end

  def test_from_markdown_unclosed_code
    assert_raises(RuntimeError) do
      TgEntity::Entities.from_markdown('```')
    end
  end

  def test_from_html_bold
    entities = TgEntity::Entities.from_html('<b>test</b>')
    assert_equal 'test', entities.message
    assert_equal 1, entities.entities.length
    assert_equal 'bold', entities.entities[0]['type']
  end

  def test_from_html_italic
    entities = TgEntity::Entities.from_html('<i>test</i>')
    assert_equal 'test', entities.message
    assert_equal 1, entities.entities.length
    assert_equal 'italic', entities.entities[0]['type']
  end

  def test_from_html_underline
    entities = TgEntity::Entities.from_html('<u>test</u>')
    assert_equal 'test', entities.message
    assert_equal 1, entities.entities.length
    assert_equal 'underline', entities.entities[0]['type']
  end

  def test_from_html_strikethrough
    entities = TgEntity::Entities.from_html('<s>test</s>')
    assert_equal 'test', entities.message
    assert_equal 1, entities.entities.length
    assert_equal 'strikethrough', entities.entities[0]['type']
  end

  def test_from_html_code
    entities = TgEntity::Entities.from_html('<code>test</code>')
    assert_equal 'test', entities.message
    assert_equal 1, entities.entities.length
    assert_equal 'code', entities.entities[0]['type']
  end

  def test_from_html_pre
    entities = TgEntity::Entities.from_html('<pre language="php">test</pre>')
    assert_equal 'test', entities.message
    assert_equal 1, entities.entities.length
    assert_equal 'pre', entities.entities[0]['type']
    assert_equal 'php', entities.entities[0]['language']
  end

  def test_from_html_link
    entities = TgEntity::Entities.from_html('<a href="https://example.com">test</a>')
    assert_equal 'test', entities.message
    assert_equal 1, entities.entities.length
    assert_equal 'text_link', entities.entities[0]['type']
    assert_equal 'https://example.com', entities.entities[0]['url']
  end

  def test_from_html_br
    entities = TgEntity::Entities.from_html('<b>test</b><br>test')
    assert_equal "test\ntest", entities.message
  end

  def test_from_html_br_self_closing
    entities = TgEntity::Entities.from_html('<b>test</b><br/>test')
    assert_equal "test\ntest", entities.message
  end

  def test_from_html_spoiler
    entities = TgEntity::Entities.from_html('<tg-spoiler>test</tg-spoiler>')
    assert_equal 'test', entities.message
    assert_equal 1, entities.entities.length
    assert_equal 'spoiler', entities.entities[0]['type']
  end

  def test_from_html_custom_emoji
    entities = TgEntity::Entities.from_html('<tg-emoji emoji-id="12345">test</tg-emoji>')
    assert_equal 'test', entities.message
    assert_equal 1, entities.entities.length
    assert_equal 'custom_emoji', entities.entities[0]['type']
    assert_equal 12345, entities.entities[0]['custom_emoji_id']
  end

  def test_from_html_text_mention
    entities = TgEntity::Entities.from_html('<a href="tg://user?id=12345">test</a>')
    assert_equal 'test', entities.message
    assert_equal 1, entities.entities.length
    assert_equal 'text_mention', entities.entities[0]['type']
    assert_equal 12345, entities.entities[0]['user']['id']
  end

  def test_from_html_nested
    entities = TgEntity::Entities.from_html('<b>bold <i>italic</i> bold</b>')
    assert_equal 'bold italic bold', entities.message
    assert_equal 2, entities.entities.length
    assert_equal 'italic', entities.entities[0]['type']
    assert_equal 'bold', entities.entities[1]['type']
  end

  def test_to_html_bold
    entities = TgEntity::Entities.new('test', [{'type' => 'bold', 'offset' => 0, 'length' => 4}])
    assert_equal '<b>test</b>', entities.to_html
  end

  def test_to_html_italic
    entities = TgEntity::Entities.new('test', [{'type' => 'italic', 'offset' => 0, 'length' => 4}])
    assert_equal '<i>test</i>', entities.to_html
  end

  def test_to_html_code
    entities = TgEntity::Entities.new('test', [{'type' => 'code', 'offset' => 0, 'length' => 4}])
    assert_equal '<code>test</code>', entities.to_html
  end

  def test_to_html_pre
    entities = TgEntity::Entities.new('test', [{'type' => 'pre', 'offset' => 0, 'length' => 4, 'language' => 'php'}])
    assert_equal '<pre language="php">test</pre>', entities.to_html
  end

  def test_to_html_text_link
    entities = TgEntity::Entities.new('test', [{'type' => 'text_link', 'offset' => 0, 'length' => 4, 'url' => 'https://example.com'}])
    assert_equal '<a href="https://example.com">test</a>', entities.to_html
  end

  def test_to_html_spoiler
    entities = TgEntity::Entities.new('test', [{'type' => 'spoiler', 'offset' => 0, 'length' => 4}])
    assert_equal '<span class="tg-spoiler">test</span>', entities.to_html
    assert_equal '<tg-spoiler>test</tg-spoiler>', entities.to_html(true)
  end

  def test_to_html_custom_emoji
    entities = TgEntity::Entities.new('test', [{'type' => 'custom_emoji', 'offset' => 0, 'length' => 4, 'custom_emoji_id' => 12345}])
    assert_equal 'test', entities.to_html
    assert_equal '<tg-emoji emoji-id="12345">test</tg-emoji>', entities.to_html(true)
  end

  def test_to_html_nested
    entities = TgEntity::Entities.new('test', [
      {'type' => 'italic', 'offset' => 0, 'length' => 4},
      {'type' => 'bold', 'offset' => 0, 'length' => 4}
    ])
    html = entities.to_html
    assert_match(/<b>/, html)
    assert_match(/<i>/, html)
  end

  def test_to_html_escape
    entities = TgEntity::Entities.new('<b>test</b>', [])
    assert_equal '&lt;b&gt;test&lt;/b&gt;', entities.to_html
  end

  def test_to_markdown_bold
    entities = TgEntity::Entities.new('test', [{'type' => 'bold', 'offset' => 0, 'length' => 4}])
    markdown = entities.to_markdown
    assert_match(/\*test\*/, markdown)
  end

  def test_to_markdown_italic
    entities = TgEntity::Entities.new('test', [{'type' => 'italic', 'offset' => 0, 'length' => 4}])
    markdown = entities.to_markdown
    assert_match(/_test_/, markdown)
  end

  def test_to_markdown_code
    entities = TgEntity::Entities.new('test', [{'type' => 'code', 'offset' => 0, 'length' => 4}])
    markdown = entities.to_markdown
    assert_match(/`test`/, markdown)
  end

  def test_to_markdown_pre
    entities = TgEntity::Entities.new('test', [{'type' => 'pre', 'offset' => 0, 'length' => 4, 'language' => 'php'}])
    markdown = entities.to_markdown
    assert_match(/```php/, markdown)
    assert_match(/test/, markdown)
    assert_match(/```/, markdown)
  end

  def test_to_markdown_text_link
    entities = TgEntity::Entities.new('text', [{'type' => 'text_link', 'offset' => 0, 'length' => 4, 'url' => 'https://example.com'}])
    markdown = entities.to_markdown
    assert_match(/\[text\]\(https:\/\/example\.com\)/, markdown)
  end

  def test_to_markdown_custom_emoji
    entities = TgEntity::Entities.new('text', [{'type' => 'custom_emoji', 'offset' => 0, 'length' => 4, 'custom_emoji_id' => 12345}])
    markdown = entities.to_markdown
    assert_match(/!\[text\]\(tg:\/\/emoji\?id=12345\)/, markdown)
  end

  def test_to_markdown_nested
    entities = TgEntity::Entities.new('test', [
      {'type' => 'italic', 'offset' => 0, 'length' => 4},
      {'type' => 'bold', 'offset' => 0, 'length' => 4}
    ])
    markdown = entities.to_markdown
    assert_match(/\*/, markdown)
    assert_match(/_/, markdown)
  end

  def test_utf16_emoji
    entities = TgEntity::Entities.from_markdown('*👍*')
    assert_equal '👍', entities.message
    assert_equal 1, entities.entities.length
    assert_equal 0, entities.entities[0]['offset']
    assert_equal 2, entities.entities[0]['length'] # Emoji is 2 UTF-16 code units
  end

  def test_utf16_flag
    entities = TgEntity::Entities.from_markdown('*🇺🇦*')
    assert_equal '🇺🇦', entities.message
    assert_equal 1, entities.entities.length
    assert_equal 0, entities.entities[0]['offset']
    assert_equal 4, entities.entities[0]['length'] # Flag is 4 UTF-16 code units
  end

  def test_round_trip_markdown_html
    original = '*bold _italic_ bold*'
    entities = TgEntity::Entities.from_markdown(original)
    html = entities.to_html
    entities2 = TgEntity::Entities.from_html(html)
    assert_equal entities.message, entities2.message
    # Entities might be slightly different due to whitespace trimming, but message should match
  end

  def test_round_trip_html_markdown
    original = '<b>bold <i>italic</i> bold</b>'
    entities = TgEntity::Entities.from_html(original)
    markdown = entities.to_markdown
    entities2 = TgEntity::Entities.from_markdown(markdown)
    assert_equal entities.message, entities2.message
  end
end
