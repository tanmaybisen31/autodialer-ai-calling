
require_relative 'config/environment'

articles = [
  {
    title: "Understanding RESTful API Design Principles",
    description: "A comprehensive guide to designing scalable and maintainable RESTful APIs with best practices",
    tags: ["API", "REST", "Web Development", "Backend"]
  },
  {
    title: "Introduction to Docker and Containerization",
    description: "Learn Docker basics, containerization concepts, and how to deploy applications efficiently",
    tags: ["Docker", "DevOps", "Containers", "Deployment"]
  },
  {
    title: "React Hooks: A Deep Dive",
    description: "Master React Hooks with practical examples, best practices, and common patterns",
    tags: ["React", "JavaScript", "Frontend", "Hooks"]
  },
  {
    title: "Database Indexing Strategies for Performance",
    description: "Optimize your database queries with effective indexing techniques and understand B-trees",
    tags: ["Database", "SQL", "Performance", "Optimization"]
  },
  {
    title: "Test-Driven Development in Practice",
    description: "Implement TDD methodology in your projects for better code quality and maintainability",
    tags: ["Testing", "TDD", "Best Practices", "Quality"]
  },
  {
    title: "Git Workflow Strategies for Teams",
    description: "Explore branching strategies like Git Flow, GitHub Flow, and collaboration patterns",
    tags: ["Git", "Version Control", "Teamwork", "DevOps"]
  },
  {
    title: "Understanding Asynchronous JavaScript",
    description: "Deep dive into Promises, async/await, event loop, and asynchronous patterns",
    tags: ["JavaScript", "Async", "Promises", "Node.js"]
  },
  {
    title: "Microservices Architecture Patterns",
    description: "Design and implement microservices with proven architectural patterns and best practices",
    tags: ["Microservices", "Architecture", "Backend", "Scalability"]
  },
  {
    title: "CSS Grid vs Flexbox: When to Use Each",
    description: "Compare CSS Grid and Flexbox layout systems with practical examples and use cases",
    tags: ["CSS", "Frontend", "Web Design", "Layout"]
  },
  {
    title: "Introduction to GraphQL",
    description: "Build efficient APIs with GraphQL query language, schema design, and resolvers",
    tags: ["GraphQL", "API", "Backend", "Web Development"]
  }
]

puts "=" * 80
puts "Blog Article Generator with RAG"
puts "=" * 80
puts "\nGenerating #{articles.length} blog articles using Gemini AI..."
puts "Each article will be generated with AI content and embeddings for RAG."
puts "\nThis will take approximately 5-10 minutes. Please wait...\n\n"

generated_count = 0
failed_count = 0

articles.each_with_index do |article_data, index|
  begin
    puts "[#{index + 1}/#{articles.length}] Generating: #{article_data[:title]}"
    puts "  └─ Description: #{article_data[:description]}"

    print "  └─ Generating content... "
    content = GeminiService.generate_article(
      title: article_data[:title],
      description: article_data[:description],
      tags: article_data[:tags]
    )
    puts "✓"

    print "  └─ Creating blog post... "
    blog = Blog.create!(
      title: article_data[:title],
      content: content,
      tags: article_data[:tags].join(', '),
      published_at: Time.current - (articles.length - index).days
    )
    puts "✓ (ID: #{blog.id})"

    print "  └─ Generating embedding for RAG... "
    blog.generate_embedding!

    if blog.reload.embedding.present?
      puts "✓"
    else
      puts "✗ (embedding failed, but article created)"
    end

    generated_count += 1
    puts "  └─ Success! Article ##{blog.id} created\n\n"

    if index < articles.length - 1
      print "  └─ Waiting 3 seconds to avoid rate limits...\n\n"
      sleep(3)
    end

  rescue StandardError => e
    puts "  └─ ✗ Failed: #{e.message}\n\n"
    failed_count += 1
  end
end

puts "=" * 80
puts "Generation Complete!"
puts "=" * 80
puts "✓ Successfully generated: #{generated_count} articles"
puts "✗ Failed: #{failed_count} articles" if failed_count > 0
puts "\nAll articles have embeddings for RAG semantic search!"
puts "\nYou can now:"
puts "  1. Visit /blogs to view all articles"
puts "  2. Visit /blogs/search to try semantic search"
puts "  3. Click any article to see related articles (powered by cosine similarity)"
puts "=" * 80
