
API_KEY="${GEMINI_API_KEY:-your_gemini_api_key_here}"
DB_PATH="db/development.sqlite3"

echo "============================================================"
echo "Generating embeddings for all articles..."
echo "============================================================"

sqlite3 "$DB_PATH" -separator '|' "SELECT id, title, content, tags FROM blogs ORDER BY id" | while IFS='|' read -r id title content tags; do
    echo ""
    echo "[$id/10] Processing: $title"

    text_for_embedding="${title}\n\n${content}\n\nTags: ${tags}"

    echo "  └─ Generating embedding..."

    response=$(curl -s -X POST \
        "https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent?key=${API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"models/text-embedding-004\",
            \"content\": {
                \"parts\": [{
                    \"text\": $(echo "$text_for_embedding" | jq -Rs .)
                }]
            }
        }")

    embedding=$(echo "$response" | jq -c '.embedding.values')

    if [ "$embedding" != "null" ] && [ -n "$embedding" ]; then
        embedding_escaped=$(echo "$embedding" | sed "s/'/''/g")

        sqlite3 "$DB_PATH" "UPDATE blogs SET embedding = '$embedding_escaped' WHERE id = $id"

        echo "  └─ ✓ Embedding generated and saved"
    else
        echo "  └─ ✗ Failed to generate embedding"
        echo "  └─ Response: $response"
    fi

    if [ "$id" -lt 10 ]; then
        sleep 2
    fi
done

count=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM blogs WHERE embedding IS NOT NULL")

echo ""
echo "============================================================"
echo "Embedding generation complete!"
echo "Articles with embeddings: $count/10"
echo "============================================================"
echo ""
echo "Semantic search is now ready!"
echo "Try searching for: 'graphql', 'docker', 'react hooks'"
echo "============================================================"
