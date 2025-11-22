# frozen_string_literal: true

require "test_helper"

class TestEntityTools < Minitest::Test
  def test_mb_strlen
    assert_equal 1, TgEntity::EntityTools.mb_strlen('t')
    assert_equal 1, TgEntity::EntityTools.mb_strlen('я')
    assert_equal 2, TgEntity::EntityTools.mb_strlen('👍')
    assert_equal 4, TgEntity::EntityTools.mb_strlen('🇺🇦')
  end

  def test_mb_substr
    assert_equal 'st', TgEntity::EntityTools.mb_substr('test', 2)
    assert_equal 'aя', TgEntity::EntityTools.mb_substr('aяaя', 2)
    assert_equal 'a👍', TgEntity::EntityTools.mb_substr('a👍a👍', 3)
    assert_equal '🇺🇦', TgEntity::EntityTools.mb_substr('🇺🇦🇺🇦', 4)
  end

  def test_mb_str_split
    assert_equal ['te', 'st'], TgEntity::EntityTools.mb_str_split('test', 2)
    assert_equal ['aя', 'aя'], TgEntity::EntityTools.mb_str_split('aяaя', 2)
    assert_equal ['a👍', 'a👍'], TgEntity::EntityTools.mb_str_split('a👍a👍', 3)
    assert_equal ['🇺🇦', '🇺🇦'], TgEntity::EntityTools.mb_str_split('🇺🇦🇺🇦', 4)
  end

  def test_mb_substr_replace
    assert_equal 'replacedst', TgEntity::EntityTools.mb_substr_replace('test', 'replaced', 0, 2)
    assert_equal 'tereplaced', TgEntity::EntityTools.mb_substr_replace('test', 'replaced', 2, 2)
  end

  def test_html_escape
    assert_equal '&lt;b&gt;test&lt;/b&gt;', TgEntity::EntityTools.html_escape('<b>test</b>')
    assert_equal '&quot;test&quot;', TgEntity::EntityTools.html_escape('"test"')
    assert_equal "&#39;test&#39;", TgEntity::EntityTools.html_escape("'test'")
  end

  def test_markdown_escape
    assert_equal '\\*test\\*', TgEntity::EntityTools.markdown_escape('*test*')
    assert_equal '\\_test\\_', TgEntity::EntityTools.markdown_escape('_test_')
    assert_equal '\\[test\\]', TgEntity::EntityTools.markdown_escape('[test]')
    assert_equal '\\(test\\)', TgEntity::EntityTools.markdown_escape('(test)')
    assert_equal '\\~test\\~', TgEntity::EntityTools.markdown_escape('~test~')
    assert_equal '\\`test\\`', TgEntity::EntityTools.markdown_escape('`test`')
    assert_equal '\\\\test', TgEntity::EntityTools.markdown_escape('\\test')
  end

  def test_markdown_code_escape
    assert_equal '\\`test', TgEntity::EntityTools.markdown_code_escape('`test')
    assert_equal 'test\\`', TgEntity::EntityTools.markdown_code_escape('test`')
    assert_equal '\\`test\\`', TgEntity::EntityTools.markdown_code_escape('`test`')
  end

  def test_markdown_codeblock_escape
    assert_equal '\\```test', TgEntity::EntityTools.markdown_codeblock_escape('```test')
    assert_equal 'test\\```', TgEntity::EntityTools.markdown_codeblock_escape('test```')
    assert_equal '\\```test\\```', TgEntity::EntityTools.markdown_codeblock_escape('```test```')
  end

  def test_markdown_url_escape
    assert_equal 'https://example.com/test\\)', TgEntity::EntityTools.markdown_url_escape('https://example.com/test)')
    assert_equal 'test\\)', TgEntity::EntityTools.markdown_url_escape('test)')
    assert_equal 'test', TgEntity::EntityTools.markdown_url_escape('test')
  end
end
