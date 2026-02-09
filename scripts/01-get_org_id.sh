#!/bin/bash

# 1. Environment/Env File Logic
if [ -z "$GH_PAT" ]; then
    if [ -f "migrate_repo.env" ]; then
        export $(grep -v '^#' migrate_repo.env | xargs)
    elif [ -f "../migrate_repo.env" ]; then
        export $(grep -v '^#' ../migrate_repo.env | xargs)
    else
        echo "⚠️ Note: migrate_repo.env not found, checking system environment..." >&2
    fi
fi

# 2. Final check for credentials and Org Name
if [ -z "$GH_PAT" ]; then
    echo "❌ Error: GH_PAT is not set!" >&2
    exit 1
fi

if [ -z "$GITHUB_ORG_NAME" ]; then
    echo "❌ Error: GITHUB_ORG_NAME is not set!" >&2
    exit 1
fi

# 3. Define the Query (Using the Variable instead of hardcoded name)
QUERY="query {
  organization(login: \"$GITHUB_ORG_NAME\") {
    id
  }
}"

# 4. Package and send
JSON_DATA=$(jq -n --arg q "$QUERY" '{query: $q}')

# Sending status to stderr so it doesn't mess up the JSON output
echo "🔍 Fetching Organization ID for $GITHUB_ORG_NAME..." >&2

curl -s -H "Authorization: Bearer $GH_PAT" \
     -X POST \
     -d "$JSON_DATA" \
     https://api.github.com/graphql | jq .
