## [Unreleased]

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
