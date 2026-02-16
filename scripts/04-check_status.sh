#!/bin/bash
# scripts/04-check_status.sh

QUERY='query($id: ID!) {
  node(id: $id) {
    ... on RepositoryMigration {
      id
      state
      failureReason
    }
  }
}'

JSON_DATA=$(jq -n --arg q "$QUERY" --arg id "$MIGRATION_ID" '{query: $q, variables: {id: $id}}')

curl -s -H "Authorization: Bearer $GH_PAT" \
     -X POST -d "$JSON_DATA" \
     https://api.github.com/graphql