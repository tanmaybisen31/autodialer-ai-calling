import sqlite3
import os
import glob
from datetime import datetime, timedelta

db_path = "db/development.sqlite3"
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

print("=" * 60)
print("Loading blog articles from text files...")
print("=" * 60)

cursor.execute("DELETE FROM blogs")
conn.commit()

articles_dir = "db/articles"
article_files = sorted(glob.glob(os.path.join(articles_dir, "*.txt")))

for index, file_path in enumerate(article_files):
    print(f"\n[{index + 1}/{len(article_files)}] Processing: {os.path.basename(file_path)}")

    with open(file_path, 'r') as f:
        content = f.read()

    lines = content.split('\n')
    title = ""
    tags = ""

    for line in lines:
        if line.startswith('Title:'):
            title = line.replace('Title:', '').strip()
        elif line.startswith('Tags:'):
            tags = line.replace('Tags:', '').strip()

    if not title:
        title = f"Article {index + 1}"

    article_content = content
    article_content = '\n'.join([l for l in lines if not l.startswith('Title:') and not l.startswith('Tags:')])
    article_content = article_content.strip()

    days_ago = len(article_files) - index
    published_at = (datetime.now() - timedelta(days=days_ago)).strftime('%Y-%m-%d %H:%M:%S')
    created_at = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    updated_at = created_at

    cursor.execute("""
        INSERT INTO blogs (title, content, tags, published_at, created_at, updated_at, embedding)
        VALUES (?, ?, ?, ?, ?, ?, NULL)
    """, (title, article_content, tags, published_at, created_at, updated_at))

    blog_id = cursor.lastrowid

    print(f"  ✓ Created: {title} (ID: {blog_id})")
    print(f"  └─ Tags: {tags}")
    print(f"  └─ Length: {len(article_content)} chars")

conn.commit()

cursor.execute("SELECT COUNT(*) FROM blogs")
count = cursor.fetchone()[0]

print("\n" + "=" * 60)
print(f"Completed! Articles loaded: {count}")
print("=" * 60)
print("\nRefresh your browser to see the articles!")
print("Visit /blogs to view all articles")
print("Visit /blogs/ask to start asking questions with RAG!")
print("=" * 60)
print("\nNote: Embeddings will be generated automatically when you")
print("first visit the RAG Q&A page or use semantic search.")
print("=" * 60)

conn.close()
