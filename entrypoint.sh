#!/bin/sh

github_token="$INPUT_TOKEN"
github_repo="$INPUT_REPO"
port_client_id="$INPUT_PORTCLIENTID"
port_client_secret="$INPUT_PORTCLIENTSECRET"
blueprint_identifier="$INPUT_BLUEPRINTIDENTIFIER"

echo "Getting collaborators and teams for $github_repo"

collaborators=$(curl -s \
  --header "Authorization: Bearer $github_token" \
  --header "Accept: application/vnd.github.v3+json" \
  --request GET \
  "https://api.github.com/repos/${github_repo}/collaborators" \
  | jq -r '.[].login')


teams=$(curl -s \
  --header "Authorization: Bearer $github_token" \
  --header "Accept: application/vnd.github.v3+json" \
  --request GET \
  "https://api.github.com/repos/${github_repo}/teams" \
  | jq -r '.[].slug')

# Convert collaborators and teams to JSON arrays
access_token=$(curl -s --location --request POST 'https://api.getport.io/v1/auth/access_token' --header 'Content-Type: application/json' --data-raw "{
    \"clientId\": \"$port_client_id\",
    \"clientSecret\": \"$port_client_secret\"
}" | jq -r '.accessToken')

echo "Validating if a blueprint with the identifier $blueprint_identifier identifier exists in Port"

response=$(curl -s \
  --request GET \
  --header "Authorization: Bearer $access_token" \
  --header "Content-Type: application/json" \
  "https://api.getport.io/v1/blueprints/$blueprint_identifier")

echo "Get blueprint response: $response"

if [ "$(echo "$response" | jq -r .error)" = "not_found" ]; then
  curl -s \
    --request POST \
    --header "Authorization: Bearer $access_token" \
    --header "User-Agent: github-action/v1.0" \
    --header "Content-Type: application/json" \
      'https://api.getport.io/v1/blueprints' \
    --data-raw "{
        \"identifier\": \"$blueprint_identifier\",
        \"title\": \"$blueprint_identifier\",
        \"icon\": \"Service\",
        \"schema\": {
          \"properties\": {
            \"collaborators\": {
                \"type\": \"array\",
                \"title\": \"Collaborators\",
                \"items\": {
                    \"type\": \"string\",
                    \"format\": \"user\"
                }
            }
          },
          \"required\": []
        },
        \"calculationProperties\": {},
        \"mirrorProperties\": {},
        \"relations\": {}
      }"
  elif [ $(echo "$response" | jq -r '.blueprint.schema.properties | has("collaborators")' ) = false ]; then
    echo "Blueprint $blueprint_identifier does not have a collaborators property, exiting..."
    exit 1
fi

echo "Checking if team exists in Port and creating it if it doesn't"

for team in "${teams[@]}"
do
  # Check if the team exists in Port
  response=$(curl -s \
    --request GET \
    --header "Authorization: Bearer $access_token" \
    --header "Content-Type: application/json" \
    "https://api.getport.io/v1/teams/$team")
  
  echo "Get team response: $response"
  echo "$team"
  if [ "$(echo "$response" | jq -r .error)" = "team_not_found" ]; then
    # If the team doesn't exist, create it in Port
    curl -s \
      --request POST \
      --header "Authorization: Bearer $access_token" \
      --header "Content-Type: application/json" \
      --data-raw "{
        \"name\": \"$team\",
        \"users\": []
      }" \
      "https://api.getport.io/v1/teams"
      
    echo "Team $team created in Port"
  else
    echo "Team $team already exists in Port"
  fi
done

collaborators=$(echo "$collaborators" | jq -R . | jq -s .)
teams=$(echo "$teams" | jq -R . | jq -s .)

github_repo_without_org=$(echo $github_repo | cut -d'/' -f2)

curl -s \
  --request POST \
  --header "Authorization: Bearer $access_token" \
  --header "Content-Type: application/json" \
  --data-raw "{
    \"identifier\": \"$github_repo_without_org\",
    \"title\": \"$github_repo_without_org\",
    \"team\": $teams,
    \"properties\": {
      \"collaborators\": $collaborators
    }
  }" \
  "https://api.getport.io/v1/blueprints/$blueprint_identifier/entities?upsert=true&merge=true"