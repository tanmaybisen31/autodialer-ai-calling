namespace :blog do
  desc "Generate 10 initial blog articles using AI"
  task generate_initial_articles: :environment do
    articles = [
      {
        title: "Understanding RESTful API Design Principles",
        description: "A comprehensive guide to designing scalable and maintainable RESTful APIs",
        tags: ["API", "REST", "Web Development", "Backend"]
      },
      {
        title: "Introduction to Docker and Containerization",
        description: "Learn Docker basics, containerization concepts, and how to deploy applications",
        tags: ["Docker", "DevOps", "Containers", "Deployment"]
      },
      {
        title: "React Hooks: A Deep Dive",
        description: "Master React Hooks with practical examples and best practices",
        tags: ["React", "JavaScript", "Frontend", "Hooks"]
      },
      {
        title: "Database Indexing Strategies for Performance",
        description: "Optimize your database queries with effective indexing techniques",
        tags: ["Database", "SQL", "Performance", "Optimization"]
      },
      {
        title: "Test-Driven Development in Practice",
        description: "Implement TDD methodology in your projects for better code quality",
        tags: ["Testing", "TDD", "Best Practices", "Quality"]
      },
      {
        title: "Git Workflow Strategies for Teams",
        description: "Explore branching strategies and collaboration patterns in Git",
        tags: ["Git", "Version Control", "Teamwork", "DevOps"]
      },
      {
        title: "Understanding Asynchronous JavaScript",
        description: "Deep dive into Promises, async/await, and event loop",
        tags: ["JavaScript", "Async", "Promises", "Node.js"]
      },
      {
        title: "Microservices Architecture Patterns",
        description: "Design and implement microservices with proven architectural patterns",
        tags: ["Microservices", "Architecture", "Backend", "Scalability"]
      },
      {
        title: "CSS Grid vs Flexbox: When to Use Each",
        description: "Compare CSS Grid and Flexbox layout systems with practical examples",
        tags: ["CSS", "Frontend", "Web Design", "Layout"]
      },
      {
        title: "Introduction to GraphQL",
        description: "Build efficient APIs with GraphQL query language and schema design",
        tags: ["GraphQL", "API", "Backend", "Web Development"]
      }
    ]

    puts "Starting to generate #{articles.length} blog articles..."
    puts "This may take several minutes. Please wait...\n\n"

    generated_count = 0
    failed_count = 0

    articles.each_with_index do |article_data, index|
      begin
        puts "[#{index + 1}/#{articles.length}] Generating: #{article_data[:title]}"

        content = GeminiService.generate_article(
          title: article_data[:title],
          description: article_data[:description],
          tags: article_data[:tags]
        )

        blog = Blog.create!(
          title: article_data[:title],
          content: content,
          tags: article_data[:tags].join(', '),
          published_at: Time.current - (articles.length - index).days
        )

        puts "  ✓ Successfully created blog ##{blog.id}"
        generated_count += 1

        # Add a small delay to avoid rate limiting
        sleep(2) if index < articles.length - 1

      rescue StandardError => e
        puts "  ✗ Failed: #{e.message}"
        failed_count += 1
      end

      puts ""
    end

    puts "=" * 60
    puts "Generation complete!"
    puts "Successfully generated: #{generated_count} articles"
    puts "Failed: #{failed_count} articles" if failed_count > 0
    puts "=" * 60
  end

  desc "Delete all blog articles"
  task clear_all: :environment do
    count = Blog.count
    Blog.destroy_all
    puts "Deleted #{count} blog articles."
  end
end
