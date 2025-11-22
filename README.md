# TgEntity

Ruby gem for converting Telegram message entities between HTML and Markdown formats. Supports all Telegram MessageEntity types with UTF-16 offset/length handling.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add telegram_entities
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install telegram_entities
```

## Usage

### Converting from Markdown to Entities

```ruby
require 'telegram_entities'

entities = TelegramEntities.from_markdown('*bold* _italic_ `code`')
# => #<TelegramEntities::Entities:0x...>
# entities.message => "bold italic code"
# entities.entities => [{"type"=>"bold", "offset"=>0, "length"=>4}, ...]
```

### Converting from HTML to Entities

```ruby
entities = TelegramEntities.from_html('<b>bold</b> <i>italic</i>')
# => #<TelegramEntities::Entities:0x...>
```

### Converting Entities to HTML

```ruby
entities = TelegramEntities.new('Hello', [
  {'type' => 'bold', 'offset' => 0, 'length' => 5}
])
html = entities.to_html
# => "<strong>Hello</strong>"

# With Telegram-specific tags
html = entities.to_html(allow_telegram_tags: true)
# => "<strong>Hello</strong>"
```

## Supported Entity Types

The gem supports all Telegram MessageEntity types:

### Text Formatting
- **`bold`** - Bold text (`<b>`)
- **`italic`** - Italic text (`<i>`)
- **`underline`** - Underlined text (`<u>`)
- **`strike`** - Strikethrough text (`<s>`)
- **`code`** - Inline code (`<code>`)
- **`pre`** - Code block (`<pre>`) with optional `language` field
- **`spoiler`** - Spoiler text (`<tg-spoiler>` or `<span class="tg-spoiler">`)

### Links and References
- **`mention`** - Username mention (@username) - converted to `<a href="https://t.me/username">`
- **`mention_name`** - User mention by ID - requires `user.id` field, converted to `<a href="tg://user?id=...">`
- **`hashtag`** - Hashtag (#hashtag)
- **`cashtag`** - Cashtag ($USD)
- **`bot_command`** - Bot command (/start)
- **`url`** - URL (automatically detected)
- **`email`** - Email address (automatically detected)
- **`phone`** - Phone number (automatically detected)
- **`text_url`** - Text link - requires `url` field, converted to `<a href="...">`

### Media and Special
- **`custom_emoji`** - Custom emoji - requires `custom_emoji_id` field
- **`media_timestamp`** - Media timestamp - requires `media_timestamp` field (integer)
- **`bank_card`** - Bank card number

### Block Quotes
- **`blockquote`** - Block quote (`<blockquote>`)
- **`expandable_blockquote`** - Expandable block quote (`<blockquote expandable>` or `<blockquote class="expandable">`)

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

**Note:** All offsets and lengths are in UTF-16 code units, not bytes or characters. The gem handles UTF-16 encoding automatically.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/telegram_entities. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/telegram_entities/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TelegramEntities project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/telegram_entities/blob/master/CODE_OF_CONDUCT.md).
