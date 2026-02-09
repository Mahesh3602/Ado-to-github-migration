#!/bin/bash
# Usage: ./01-get_org_id.sh

# 1. Only try to load the .env file if the variable is missing (Local Testing)
if [ -z "$GH_PAT" ]; then
    if [ -f "migrate_repo.env" ]; then
        export $(grep -v '^#' migrate_repo.env | xargs)
    elif [ -f "../migrate_repo.env" ]; then
        export $(grep -v '^#' ../migrate_repo.env | xargs)
    else
        # In GitHub Actions, we don't want to exit here!
        # We only exit if the variable is STILL empty after checking everything.
        echo "⚠️ Note: migrate_repo.env not found, checking system environment..." >&2
    fi
fi

# 2. Final check: If the variable is still empty, THEN exit.
if [ -z "$GH_PAT" ]; then
    echo "❌ Error: GH_PAT is not set in .env or environment variables!" >&2
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
