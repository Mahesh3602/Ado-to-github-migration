#!/bin/bash

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
