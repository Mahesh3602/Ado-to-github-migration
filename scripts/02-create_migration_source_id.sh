#!/bin/bash
[ -f migrate_repo.env ] && export $(grep -v '^#' migrate_repo.env | xargs)

QUERY='mutation($ownerId: ID!, $name: String!) {
  createMigrationSource(input: {
    name: $name,
    url: "https://dev.azure.com",
    ownerId: $ownerId,
    type: AZURE_DEVOPS
  }) {
    migrationSource { id }
  }
}'

JSON_DATA=$(jq -n \
  --arg q "$QUERY" \
  --arg id "$ORG_ID" \
  --arg name "Source-$GITHUB_ORG_NAME" \
  '{query: $q, variables: {ownerId: $id, name: $name}}')

curl -s -H "Authorization: Bearer $GH_PAT" \
     -X POST -d "$JSON_DATA" \
     https://api.github.com/graphql