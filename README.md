# TelegramEntities

[![Ruby Version](https://img.shields.io/badge/ruby-%3E%3D%203.1.0-red.svg)](https://www.ruby-lang.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE.txt)
[![Gem Version](https://img.shields.io/gem/v/telegram_entities.svg)](https://rubygems.org/gems/telegram_entities)

Ruby gem for converting Telegram message entities between HTML and Markdown formats. Supports all Telegram MessageEntity types with UTF-16 offset/length handling.

📚 **Official Telegram Documentation:**
- [MessageEntity Types](https://core.telegram.org/type/MessageEntity) - Complete schema of all entity types
- [Styled Text with Message Entities](https://core.telegram.org/api/entities) - How Telegram styles text using entities

## Features

✨ **Full Telegram Support** - All MessageEntity types supported  
🔀 **Bidirectional Conversion** - Convert between HTML, Markdown, and Telegram entities  
🌐 **UTF-16 Handling** - Automatic UTF-16 offset/length calculation  
📦 **Zero Dependencies** - Only requires Nokogiri for HTML parsing  
🚀 **Easy to Use** - Simple, intuitive API

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add telegram_entities
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install telegram_entities
```

## Quick Start

```ruby
require 'telegram_entities'

# Convert Markdown to Telegram entities
entities = TelegramEntities.from_markdown('*bold* _italic_ `code`')
puts entities.message
# => "bold italic code"

puts entities.entities
# => [
#   {"type"=>"bold", "offset"=>0, "length"=>4},
#   {"type"=>"italic", "offset"=>5, "length"=>6},
#   {"type"=>"code", "offset"=>12, "length"=>4}
# ]
```

## Usage

### Converting from Markdown to Entities

Parse Markdown text and extract Telegram entities:

```ruby
require 'telegram_entities'

text = '*Hello* _world_! Visit https://example.com'
entities = TelegramEntities.from_markdown(text)

puts entities.message
# => "Hello world! Visit https://example.com"

puts entities.entities.inspect
# => [
#   {"type"=>"bold", "offset"=>0, "length"=>5},
#   {"type"=>"italic", "offset"=>6, "length"=>5},
#   {"type"=>"url", "offset"=>18, "length"=>19}
# ]
```

### Converting from HTML to Entities

Parse HTML and extract Telegram entities:

```ruby
html = '<b>bold</b> <i>italic</i> <a href="https://example.com">link</a>'
entities = TelegramEntities.from_html(html)

puts entities.message
# => "bold italic link"

puts entities.entities
# => [
#   {"type"=>"bold", "offset"=>0, "length"=>4},
#   {"type"=>"italic", "offset"=>5, "length"=>6},
#   {"type"=>"text_url", "offset"=>12, "length"=>4, "url"=>"https://example.com"}
# ]
```

### Converting Entities to HTML

Convert Telegram entities back to HTML:

```ruby
# Create entities manually
entities = TelegramEntities.new('Hello world', [
  {'type' => 'bold', 'offset' => 0, 'length' => 5},
  {'type' => 'italic', 'offset' => 6, 'length' => 5}
])

html = entities.to_html
puts html
# => "<strong>Hello</strong> <em>world</em>"
```

### Telegram-Specific Tags

When sending HTML to Telegram Bot API, use `allow_telegram_tags: true` to get Telegram-compatible tags. This is especially important for special entity types like spoilers, custom emojis, and cashtags:

```ruby
# Create entities with Telegram-specific types
# Message: "$BTC 🚀 secret"
entities = TelegramEntities.new('$BTC 🚀 secret', [
  {'type' => 'cashtag', 'offset' => 0, 'length' => 4},      # $BTC
  {'type' => 'custom_emoji', 'offset' => 5, 'length' => 2, 'custom_emoji_id' => 12345},  # 🚀
  {'type' => 'spoiler', 'offset' => 7, 'length' => 6}      # secret
])

# Standard HTML (for web display)
html_standard = entities.to_html
puts html_standard
# => "<span class=\"tg-cashtag\">$BTC</span> 🚀 <span class=\"tg-spoiler\">secret</span>"

# Telegram-specific tags (for Telegram Bot API)
html_telegram = entities.to_html(allow_telegram_tags: true)
puts html_telegram
# => "<tg-cashtag>$BTC</tg-cashtag> <tg-emoji emoji-id=\"12345\">🚀</tg-emoji> <tg-spoiler>secret</tg-spoiler>"
```

**Key differences for Telegram-specific entities:**

| Entity Type | Standard HTML | Telegram Tags |
|-------------|---------------|---------------|
| **Spoiler** | `<span class="tg-spoiler">text</span>` | `<tg-spoiler>text</tg-spoiler>` |
| **Custom Emoji** | `🚀` (plain text, no tags) | `<tg-emoji emoji-id="12345">🚀</tg-emoji>` |
| **Cashtag** | `<span class="tg-cashtag">$BTC</span>` | `<tg-cashtag>$BTC</tg-cashtag>` |
| **Hashtag** | `<span class="tg-hashtag">#tag</span>` | `<tg-hashtag>#tag</tg-hashtag>` |
| **Bot Command** | `<span class="tg-bot-command">/start</span>` | `<tg-bot-command>/start</tg-bot-command>` |

**When to use each mode:**
- **Standard HTML** (`allow_telegram_tags: false`): For displaying in web browsers or general HTML rendering
- **Telegram Tags** (`allow_telegram_tags: true`): For sending messages via Telegram Bot API using `parse_mode: 'HTML'`

### Real-World Example

```ruby
require 'telegram_entities'

# User sends a message with Markdown
user_input = '*Important*: Check out https://github.com/qelphybox/telegram_entities_rb'

# Convert to Telegram entities for Bot API
entities = TelegramEntities.from_markdown(user_input)

# Send to Telegram Bot API
# bot.send_message(
#   chat_id: chat_id,
#   text: entities.message,
#   entities: entities.entities
# )

# Later, convert received entities back to HTML for display
html_entities = TelegramEntities.new(entities.message, entities.entities)
html_output = html_entities.to_html
# => "<strong>Important</strong>: Check out <a href=\"https://github.com/qelphybox/telegram_entities_rb\">https://github.com/qelphybox/telegram_entities_rb</a>"
```

## Supported Entity Types

The gem supports **all** Telegram MessageEntity types. Here's a complete reference:

> 📖 For the complete list of entity types and their specifications, see the [official Telegram documentation](https://core.telegram.org/type/MessageEntity).

### 📝 Text Formatting

| Type | Markdown | HTML | Description |
|------|----------|------|-------------|
| `bold` | `*text*` or `**text**` | `<b>text</b>` | Bold text |
| `italic` | `_text_` or `*text*` | `<i>text</i>` | Italic text |
| `underline` | `__text__` | `<u>text</u>` | Underlined text |
| `strike` | `~~text~~` | `<s>text</s>` | Strikethrough text |
| `code` | `` `code` `` | `<code>code</code>` | Inline code |
| `pre` | ` ```code``` ` | `<pre>code</pre>` | Code block (with optional `language`) |
| `spoiler` | `||text||` | `<tg-spoiler>text</tg-spoiler>` | Spoiler text |

### 🔗 Links and References

| Type | Example | HTML Output | Notes |
|------|---------|-------------|-------|
| `mention` | `@username` | `<a href="https://t.me/username">@username</a>` | Username mention |
| `mention_name` | User by ID | `<a href="tg://user?id=123">Name</a>` | Requires `user.id` field |
| `hashtag` | `#hashtag` | `#hashtag` | Hashtag |
| `cashtag` | `$USD` | `$USD` | Cashtag |
| `bot_command` | `/start` | `/start` | Bot command |
| `url` | `https://example.com` | `<a href="https://example.com">https://example.com</a>` | Auto-detected URL |
| `email` | `user@example.com` | `<a href="mailto:user@example.com">user@example.com</a>` | Auto-detected email |
| `phone` | `+1234567890` | `<a href="tel:+1234567890">+1234567890</a>` | Auto-detected phone |
| `text_url` | Custom link | `<a href="url">text</a>` | Requires `url` field |

### 🎨 Media and Special

| Type | Description | Required Fields |
|------|-------------|----------------|
| `custom_emoji` | Custom emoji | `custom_emoji_id` |
| `media_timestamp` | Media timestamp | `media_timestamp` (integer) |
| `bank_card` | Bank card number | - |

### 💬 Block Quotes

| Type | HTML | Description |
|------|------|-------------|
| `blockquote` | `<blockquote>text</blockquote>` | Block quote |
| `expandable_blockquote` | `<blockquote expandable>text</blockquote>` | Expandable block quote |

### Entity Structure

Each entity is a hash with the following structure:

```ruby
{
  'type' => 'bold',           # Entity type (required)
  'offset' => 0,               # UTF-16 offset (required)
  'length' => 4,               # UTF-16 length (required)
  'url' => '...',             # For text_url type
  'user' => {'id' => 123},    # For mention_name type
  'custom_emoji_id' => 12345, # For custom_emoji type
  'media_timestamp' => 30,    # For media_timestamp type
  'language' => 'ruby'         # For pre type
}
```

### Example with Complex Entities

```ruby
require 'telegram_entities'

# Complex message with multiple entity types
markdown = <<~TEXT
  *Bold* and _italic_ text with `code`.
  
  Visit https://example.com or email user@example.com
  
  ||Spoiler text||
TEXT

entities = TelegramEntities.from_markdown(markdown)

puts "Message: #{entities.message}"
puts "\nEntities (#{entities.entities.length}):"
entities.entities.each do |entity|
  puts "  - #{entity['type']}: offset=#{entity['offset']}, length=#{entity['length']}"
end
```

**Output:**
```
Message: Bold and italic text with code.

Visit https://example.com or email user@example.com

Spoiler text

Entities (5):
  - bold: offset=0, length=4
  - italic: offset=9, length=6
  - code: offset=22, length=4
  - url: offset=35, length=19
  - email: offset=59, length=19
  - spoiler: offset=82, length=11
```

**⚠️ Important Note:** All offsets and lengths are in **UTF-16 code units**, not bytes or characters. The gem handles UTF-16 encoding automatically, so you don't need to worry about it!

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/qelphybox/telegram_entities_rb](https://github.com/qelphybox/telegram_entities_rb). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/qelphybox/telegram_entities_rb/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TelegramEntities project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/qelphybox/telegram_entities_rb/blob/master/CODE_OF_CONDUCT.md).
