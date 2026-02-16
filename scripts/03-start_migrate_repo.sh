#!/bin/bash

# 1. Validation
if [[ -z "$SOURCE_ID" || -z "$ORG_ID" || -z "$ADO_REPO_URL" || -z "$GIT_REPO_NAME" || -z "$ADO_PAT" ]]; then
  echo "❌ Error: Missing required environment variables." >&2
  exit 1
fi

# 2. Define the GraphQL Mutation
# Note: We change the variable type for $sourceUrl to URI! to match the schema
QUERY='mutation($sourceId: ID!, $ownerId: ID!, $sourceUrl: URI!, $targetName: String!, $targetToken: String!) {
  startRepositoryMigration(input: {
    sourceId: $sourceId,
    ownerId: $ownerId,
    sourceRepositoryUrl: $sourceUrl,
    repositoryName: $targetName,
    accessToken: $targetToken,
    continueOnError: true,
    targetRepoVisibility: "public"
  }) {
    repositoryMigration {
      id
      state
    }
  }
}'

# 3. Package the variables with jq
JSON_DATA=$(jq -n \
  --arg q "$QUERY" \
  --arg sourceId "$SOURCE_ID" \
  --arg ownerId "$ORG_ID" \
  --arg sourceUrl "$ADO_REPO_URL" \
  --arg targetName "$GIT_REPO_NAME" \
  --arg targetToken "$ADO_PAT" \
  '{query: $q, variables: {sourceId: $sourceId, ownerId: $ownerId, sourceUrl: $sourceUrl, targetName: $targetName, targetToken: $targetToken}}')

# 4. Log to Standard Error (to keep migration_output.json clean)
echo "🚀 Starting Migration for $GIT_REPO_NAME..." >&2

# 5. Execute API call
curl -s -H "Authorization: Bearer $GH_PAT" \
     -X POST -d "$JSON_DATA" \
     https://api.github.com/graphql