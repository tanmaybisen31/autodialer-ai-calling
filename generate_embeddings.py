import sqlite3
import json
import time
import urllib.request
import urllib.error

import os

GEMINI_API_KEY = os.getenv('GEMINI_API_KEY', 'your_gemini_api_key_here')
EMBEDDING_URL = f"https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent?key={GEMINI_API_KEY}"

def generate_embedding(text):
    """Generate embedding using Gemini API"""
    try:
        data = json.dumps({
            "model": "models/text-embedding-004",
            "content": {
                "parts": [{"text": text}]
            }
        }).encode('utf-8')

        req = urllib.request.Request(
            EMBEDDING_URL,
            data=data,
            headers={"Content-Type": "application/json"}
        )

        with urllib.request.urlopen(req, timeout=30) as response:
            response_data = json.loads(response.read().decode('utf-8'))
            embedding_values = response_data.get('embedding', {}).get('values', [])
            if embedding_values:
                return json.dumps(embedding_values)
            return None

    except urllib.error.HTTPError as e:
        print(f"✗ HTTP Error: {e.code}")
        return None
    except Exception as e:
        print(f"✗ Exception: {str(e)}")
        return None

db_path = "db/development.sqlite3"
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

print("=" * 60)
print("Generating embeddings for all articles...")
print("=" * 60)

cursor.execute("SELECT id, title, content, tags FROM blogs ORDER BY id")
articles = cursor.fetchall()

success_count = 0
fail_count = 0

for article in articles:
    blog_id, title, content, tags = article
    print(f"\n[{blog_id}/10] Processing: {title}")

    text_for_embedding = f"{title}\n\n{content}\n\nTags: {tags}"

    print(f"  └─ Text length: {len(text_for_embedding)} chars")
    print(f"  └─ Generating embedding... ", end="", flush=True)

    embedding_json = generate_embedding(text_for_embedding)

    if embedding_json:
        cursor.execute(
            "UPDATE blogs SET embedding = ? WHERE id = ?",
            (embedding_json, blog_id)
        )
        conn.commit()
        print("✓")
        success_count += 1
    else:
        print("✗ (failed)")
        fail_count += 1

    if blog_id < 10:
        time.sleep(2)

cursor.execute("SELECT COUNT(*) FROM blogs WHERE embedding IS NOT NULL")
count_with_embeddings = cursor.fetchone()[0]

print("\n" + "=" * 60)
print(f"Embedding generation complete!")
print(f"Success: {success_count} articles")
print(f"Failed: {fail_count} articles")
print(f"Total with embeddings: {count_with_embeddings}/10")
print("=" * 60)
print("\nYour semantic search is now ready!")
print("Try searching for: 'graphql', 'docker', 'react hooks'")
print("=" * 60)

conn.close()
