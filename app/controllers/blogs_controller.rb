class BlogsController < ApplicationController
  def index
    @blogs = Blog.published.limit(50)
  end

  def show
    @blog = Blog.find(params[:id])
    @related_articles = @blog.find_related_articles(limit: 3)
    @rendered_content = SimpleMarkdownRenderer.render(@blog.content)
  end

  def ask
    @blogs = Blog.published.order(title: :asc)
  end

  def answer
    question = params[:question]
    blog_ids = params[:blog_ids]

    if question.blank?
      render json: { success: false, error: "Please provide a question" }, status: 400
      return
    end

    result = RagService.ask_question(question, blog_ids)

    render json: result
  end

  def search
    @query = params[:q]

    if @query.present?
      results = Blog.semantic_search(@query, limit: 10, min_similarity: 0.3)
      @blogs = results.map { |r| r[:article] }
      @similarity_scores = results.map { |r| [r[:article].id, r[:score]] }.to_h
    else
      @blogs = []
      @similarity_scores = {}
    end
  end

  def generate
  end

  def bulk_generate
    user_prompt = params[:prompt]

    if user_prompt.blank?
      render json: { success: false, error: "Please provide article titles and details" }, status: 400
      return
    end

    result = OpenaiService.generate_articles_from_prompt(user_prompt)

    if result[:success] && result[:articles].any?
      created_blogs = []
      failed_blogs = []

      result[:articles].each do |article_data|
        blog = Blog.new(
          title: article_data[:title],
          content: article_data[:content],
          tags: article_data[:tags],
          published_at: Time.current
        )

        if blog.save
          created_blogs << {
            id: blog.id,
            title: blog.title,
            url: blog_path(blog)
          }
        else
          failed_blogs << {
            title: article_data[:title],
            errors: blog.errors.full_messages
          }
        end
      end

      render json: {
        success: true,
        created: created_blogs,
        failed: failed_blogs,
        total: result[:count],
        message: "Successfully created #{created_blogs.size} blog post(s)"
      }
    else
      render json: {
        success: false,
        error: result[:error] || "Failed to generate articles"
      }, status: 422
    end
  rescue => e
    Rails.logger.error "Bulk generation error: #{e.message}"
    render json: { success: false, error: e.message }, status: 500
  end

end
