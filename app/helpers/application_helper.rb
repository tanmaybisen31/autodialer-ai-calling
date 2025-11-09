module ApplicationHelper
  def render_markdown(text)
    SimpleMarkdownRenderer.render(text)
  end
end
