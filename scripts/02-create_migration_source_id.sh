#!/bin/bash
# Usage: ./02-create_migration_source_id.sh

# 1. Load your Environment Variables
if [ -f migrate_repo.env ]; then
    export $(grep -v '^#' migrate_repo.env | xargs)
else
    echo "❌ Error: migrate_repo.env not found!"
    exit 1
fi

# 2. Define the Query with a variable placeholder ($ownerId)
# We use a 'heredoc' to keep the query readable
QUERY='mutation($ownerId: ID!) {
  createMigrationSource(input: {
    name: "Azure DevOps Source",
    url: "https://dev.azure.com",
    ownerId: $ownerId,
    type: AZURE_DEVOPS
  }) {
    migrationSource {
      id
    }
  }
}'

# 3. Use jq to safely package the query AND the variable
# This ensures $ORG_ID is expanded by the shell and safely injected into the JSON
JSON_DATA=$(jq -n \
  --arg q "$QUERY" \
  --arg id "$ORG_ID" \
  '{query: $q, variables: {ownerId: $id}}')

echo "🚀 Registering Migration Source..."

# 4. Execute the API call
curl -s -H "Authorization: Bearer $GH_PAT" \
     -X POST \
     -d "$JSON_DATA" \
     https://api.github.com/graphql | jq .