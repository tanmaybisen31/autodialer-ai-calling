puts "Seeding database..."

puts "Clearing existing data..."
Call.destroy_all
PhoneNumber.destroy_all

puts "Creating real test numbers..."
real_numbers = [
  { number: '9999999999', name: 'Real Test Contact 1', is_test_number: false },
  { number: '8888888888', name: 'Real Test Contact 2', is_test_number: false }
]

real_numbers.each do |num_data|
  PhoneNumber.create!(
    number: num_data[:number],
    country_code: '+91',
    name: num_data[:name],
    is_test_number: num_data[:is_test_number],
    status: 'pending'
  )
  puts "  Created #{num_data[:number]}"
end

puts "Generating 98 test numbers (1800-XXX-XXXX format)..."
98.times do |i|
  random_number = "1800#{rand(100..999)}#{rand(1000..9999)}"

  begin
    PhoneNumber.create!(
      number: random_number,
      country_code: '+91',
      name: "Test Number #{i + 1}",
      is_test_number: true,
      status: 'pending'
    )
  rescue ActiveRecord::RecordNotUnique
    retry
  end
end

puts "\nDatabase seeded successfully!"
puts "Total phone numbers: #{PhoneNumber.count}"
puts "  - Real numbers: #{PhoneNumber.where(is_test_number: false).count}"
puts "  - Test numbers (1800): #{PhoneNumber.where(is_test_number: true).count}"
puts "\nYou can now:"
puts "  1. Visit http://localhost:3000 to see the interface"
puts "  2. Use the AI command: 'call 9999999999' or 'call 8888888888'"
puts "  3. Start the autodialer to call all pending numbers"
puts "\nIMPORTANT: The 1800 numbers are for testing only."
puts "Only 9999999999 and 8888888888 are real numbers that will actually receive calls."

puts "\n" + "=" * 60
puts "Loading blog articles from text files..."
puts "=" * 60

Blog.destroy_all if defined?(Blog)

articles_dir = File.join(Rails.root, 'db', 'articles')
article_files = Dir.glob(File.join(articles_dir, '*.txt')).sort

article_files.each_with_index do |file_path, index|
  puts "\n[#{index + 1}/#{article_files.length}] Processing: #{File.basename(file_path)}"

  content = File.read(file_path)

  lines = content.split("\n")
  title_line = lines.find { |line| line.start_with?('Title:') }
  tags_line = lines.find { |line| line.start_with?('Tags:') }

  title = title_line ? title_line.sub('Title:', '').strip : "Article #{index + 1}"
  tags = tags_line ? tags_line.sub('Tags:', '').strip : ""

  article_content = content.gsub(/^Title:.*\n/, '').gsub(/^Tags:.*\n/, '').strip

  blog = Blog.create!(
    title: title,
    content: article_content,
    tags: tags,
    published_at: Time.current - (article_files.length - index).days
  )

  puts "  ✓ Created: #{blog.title} (ID: #{blog.id})"
  puts "  └─ Tags: #{blog.tags}"
  puts "  └─ Content length: #{blog.content.length} characters"

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
puts "Blog articles seeded!"
puts "Total articles: #{Blog.count}"
puts "Articles with embeddings: #{Blog.where.not(embedding: nil).count}"
puts "=" * 60
puts "\nVisit /blogs to view articles and /blogs/ask for RAG Q&A!"
puts "=" * 60
