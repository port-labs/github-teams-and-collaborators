#!/bin/sh

githubToken="$INPUT_TOKEN"
githubRepo="$INPUT_REPO"
portClientId="$INPUT_PORT_CLIENT_ID"
portClientSecret="$INPUT_PORT_CLIENT_SECRET"

echo "Getting collaborators and teams for $githubRepo"

# Get Repo Users
collaborators=$(curl \
  --header "Authorization: Bearer $githubToken" \
  --header "Accept: application/vnd.github.v3+json" \
  --request GET \
  "https://api.github.com/repos/${githubRepo}/collaborators" \
  | jq -r '.[].login')

echo "Collaborators: $collaborators"

# Get Repo Teams
teams=$(curl \
  --header "Authorization: Bearer $githubToken" \
  --header "Accept: application/vnd.github.v3+json" \
  --request GET \
  "https://api.github.com/repos/${githubRepo}/teams" \
  | jq -r '.[].slug')

echo "Teams: $teams"

# Create output variables
echo "::set-output name=collaborators::$collaborators"
echo "::set-output name=teams::$teams"