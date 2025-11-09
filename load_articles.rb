require_relative 'config/environment'

puts "=" * 60
puts "Loading blog articles from text files..."
puts "=" * 60

Blog.destroy_all

articles_dir = File.join(Rails.root, 'db', 'articles')
article_files = Dir.glob(File.join(articles_dir, '*.txt')).sort

article_files.each_with_index do |file_path, index|
  puts "\n[#{index + 1}/#{article_files.length}] Processing: #{File.basename(file_path)}"

  content = File.read(file_path)
  lines = content.split("\n")
  title_line = lines.find { |line| line.start_with?('Title:') }
  tags_line = lines.find { |line| line.start_with?('Tags:') }

  title = title_line ? title_line.sub('Title:', '').strip : "Article #{index + 1}"
  tags = tags_line ? tags_line.sub('Tags:', '').strip : ''

  article_content = content.gsub(/^Title:.*\n/, '').gsub(/^Tags:.*\n/, '').strip

  blog = Blog.create!(
    title: title,
    content: article_content,
    tags: tags,
    published_at: Time.current - (article_files.length - index).days
  )

  puts "  ✓ Created: #{blog.title} (ID: #{blog.id})"
  puts "  └─ Tags: #{blog.tags}"
  puts "  └─ Length: #{blog.content.length} chars"

  print "  └─ Generating embedding for RAG... "
  blog.generate_embedding!

  if blog.reload.embedding.present?
    puts "✓"
  else
    puts "✗ (failed)"
  end

  sleep(2) if index < article_files.length - 1
end

puts "\n" + "=" * 60
puts "Completed! Articles loaded: #{Blog.count}"
puts "Articles with embeddings: #{Blog.where.not(embedding: nil).count}"
puts "=" * 60
puts "\nRefresh your browser to see the articles!"
puts "Visit /blogs/ask to start asking questions with RAG!"
puts "=" * 60
