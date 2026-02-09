#!/bin/bash

# 1. Load the variables from your env file
source migrate_repo.env

# 2. Check the status using the MIGRATION_ID from your env
QUERY="query {
  node(id: \"$MIGRATION_ID\") {
    ... on RepositoryMigration {
      state
      failureReason
    }
  }
}"

# 3. Package and Send
JSON_DATA=$(jq -n --arg q "$QUERY" '{query: $q}')

curl -s -H "Authorization: Bearer $GH_PAT" \
     -X POST \
     -d "$JSON_DATA" \
     https://api.github.com/graphql | jq '.data.node'