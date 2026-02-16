#!/bin/bash

# 1. Validation: Ensure all required variables are present
# These are provided by the 'env:' block in your GitHub Action
if [[ -z "$SOURCE_ID" || -z "$ORG_ID" || -z "$ADO_REPO_URL" || -z "$GIT_REPO_NAME" || -z "$ADO_PAT" ]]; then
  echo "❌ Error: Missing required environment variables for migration." >&2
  exit 1
fi

# 2. Define the GraphQL Mutation with variable placeholders
# This is cleaner and more 'Architect-friendly' than string interpolation
QUERY='mutation($sourceId: ID!, $ownerId: ID!, $sourceUrl: String!, $targetName: String!, $targetToken: String!) {
  startRepositoryMigration(input: {
    sourceId: $sourceId,
    ownerId: $ownerId,
    sourceRepositoryUrl: $sourceUrl,
    repositoryName: $targetName,
    accessToken: $targetToken,
    continueOnError: true,
    targetRepoVisibility: PUBLIC
  }) {
    repositoryMigration {
      id
      state
    }
  }
}'

# 3. Use jq to safely package the query AND the variables
# This ensures that URLs and Tokens are handled as safe strings
JSON_DATA=$(jq -n \
  --arg q "$QUERY" \
  --arg sourceId "$SOURCE_ID" \
  --arg ownerId "$ORG_ID" \
  --arg sourceUrl "$ADO_REPO_URL" \
  --arg targetName "$GIT_REPO_NAME" \
  --arg targetToken "$ADO_PAT" \
  '{query: $q, variables: {sourceId: $sourceId, ownerId: $ownerId, sourceUrl: $sourceUrl, targetName: $targetName, targetToken: $targetToken}}')

# 4. Log to Standard Error (this shows in the console but NOT in the JSON file)
echo "🚀 Starting Migration for $GIT_REPO_NAME..." >&2

# 5. Execute API call and output ONLY the raw JSON to Standard Output
curl -s -H "Authorization: Bearer $GH_PAT" \
     -X POST -d "$JSON_DATA" \
     https://api.github.com/graphql