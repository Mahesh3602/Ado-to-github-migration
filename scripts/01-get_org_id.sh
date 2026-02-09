#!/bin/bash
# Usage: ./01-get_org_id.sh

# 1. Load your GitHub PAT
# Make sure you have GH_PAT=your_token in your migrate_repo.env file
if [ -f migrate_repo.env ]; then
    export $(grep -v '^#' migrate_repo.env | xargs)
else
    echo "❌ Error: migrate_repo.env not found!"
    exit 1
fi

# 2. Define the Query
QUERY='query {
  organization(login: "voting-app-production") {
    id
  }
}'

# 3. Use jq to package the query and send it
# The -s flag makes curl silent, -d sends the data
JSON_DATA=$(jq -n --arg q "$QUERY" '{query: $q}')

echo "🔍 Fetching Organization ID..."

curl -s -H "Authorization: Bearer $GH_PAT" \
     -X POST \
     -d "$JSON_DATA" \
     https://api.github.com/graphql | jq .