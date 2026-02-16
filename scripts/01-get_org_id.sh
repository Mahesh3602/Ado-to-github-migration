#!/bin/bash
# If running locally, load .env. In pipeline, variables are already set.
[ -f migrate_repo.env ] && export $(grep -v '^#' migrate_repo.env | xargs)

JSON_DATA=$(jq -n --arg org "$GITHUB_ORG_NAME" \
  '{query: "query($org: String!) { organization(login: $org) { id } }", variables: {org: $org}}')

curl -s -H "Authorization: Bearer $GH_PAT" \
     -X POST -d "$JSON_DATA" \
     https://api.github.com/graphql