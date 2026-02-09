#!/bin/bash
# Usage: ./02-create_migration_source_id.sh

# 2. Define the Query with variable placeholders
QUERY="mutation {
  startRepositoryMigration(input: {
    sourceId: \"$SOURCE_ID\",
    sourceRepositoryUrl: \"$ADO_REPO_URL\",
    repositoryName: \"$GIT_REPO_NAME\",
    ownerId: \"$ORG_ID\",
    accessToken: \"$ADO_PAT\",
    githubPat: \"$GH_PAT\",
    continueOnError: true,
    targetRepoVisibility: \"public\"
  }) {
    repositoryMigration {
      id
      state
    }
  }
}"

# 3. Use jq to package the variables from your specific env fields
# id pulls from ORG_ID
# name pulls from GITHUB_ORG_NAME
JSON_DATA=$(jq -n --arg q "$QUERY" '{query: $q}')

echo "🚀 Starting Migration for $GIT_REPO_NAME..."

curl -s -H "Authorization: Bearer $GH_PAT" \
     -X POST -d "$JSON_DATA" \
     https://api.github.com/graphql | jq .