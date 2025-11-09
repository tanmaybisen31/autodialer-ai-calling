require 'erb'

class SimpleMarkdownRenderer
  class << self
    def render(text)
      return ''.html_safe if text.blank?

      html = text.dup

      convert_code_blocks!(html)
      convert_inline_code!(html)
      convert_headers!(html)
      convert_emphasis!(html)
      convert_links!(html)
      convert_lists!(html)
      convert_blockquotes!(html)

      html.gsub!(/\n\n/, '</p><p>')
      html = "<p>#{html}</p>"

      html.html_safe
    end

    private

    def convert_code_blocks!(html)
      html.gsub!(/```(\w+)?\n(.*?)```/m) do
        language = Regexp.last_match(1) || ''
        code = Regexp.last_match(2)
        "<pre><code class='language-#{language}'>#{ERB::Util.html_escape(code)}</code></pre>"
      end
    end

    def convert_inline_code!(html)
      html.gsub!(/`([^`]+)`/) { "<code>#{ERB::Util.html_escape(Regexp.last_match(1))}</code>" }
    end

    def convert_headers!(html)
      html.gsub!(/^#### (.+)$/, '<h4>\1</h4>')
      html.gsub!(/^### (.+)$/, '<h3>\1</h3>')
      html.gsub!(/^## (.+)$/, '<h2>\1</h2>')
      html.gsub!(/^# (.+)$/, '<h1>\1</h1>')
    end

    def convert_emphasis!(html)
      html.gsub!(/\*\*(.+?)\*\*/, '<strong>\1</strong>')
      html.gsub!(/__(.+?)__/, '<strong>\1</strong>')
      html.gsub!(/\*(.+?)\*/, '<em>\1</em>')
      html.gsub!(/_(.+?)_/, '<em>\1</em>')
    end

    def convert_links!(html)
      html.gsub!(/\[([^\]]+)\]\(([^)]+)\)/, '<a href="\2">\1</a>')
    end

    def convert_lists!(html)
      html.gsub!(/^\* (.+)$/, '<li>\1</li>')
      html.gsub!(/(<li>.*<\/li>\n?)+/m) { "<ul>#{$&}</ul>" }
      html.gsub!(/^\d+\. (.+)$/, '<li>\1</li>')
    end

    def convert_blockquotes!(html)
      html.gsub!(/^> (.+)$/, '<blockquote>\1</blockquote>')
    end
  end
end
