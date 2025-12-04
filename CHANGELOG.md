## [Unreleased]

## [0.2.0] - 2025-12-04

### Added
- New method `to_bot_html` for formatting HTML specifically for Telegram Bot API `parse_mode: 'HTML'`
- Automatic replacement of `<br>` and `<br/>` tags with `\n` characters
- Automatic removal of wrappers for hashtags, cashtags, bot commands, media timestamps, and bank card numbers (these are automatically processed by Telegram)
- Proper HTML entity escaping for `<`, `>`, `&`, and `"` symbols
- Support for named HTML entities (`&lt;`, `&gt;`, `&amp;`, `&quot;`)
- Support for numeric HTML entities (decimal and hexadecimal)

### Changed
- Improved documentation with examples for `to_bot_html` method
- Added reference to Telegram Bot API HTML Style documentation

## [0.1.0] - 2025-11-22

### Added
- Initial release
- Support for all Telegram MessageEntity types
- Conversion from Markdown to Telegram entities (`from_markdown`)
- Conversion from HTML to Telegram entities (`from_html`)
- Conversion from Telegram entities to HTML (`to_html`)
- Support for Telegram-specific HTML tags (`allow_telegram_tags` option)
- UTF-16 offset/length handling for all entity types
- Support for TDLib formattedText conversion (`from_tdlib_formatted_text`)
