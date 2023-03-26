#!/bin/sh

githubToken="$INPUT_TOKEN"
githubRepo="$INPUT_REPO"
portClientId="$INPUT_PORT_CLIENT_ID"
portClientSecret="$INPUT_PORT_CLIENT_SECRET"
blueprintIdentifier="$INPUT_BLUEPRINT_IDENTIFIER"

echo "Getting collaborators and teams for $githubRepo"

# Get Repo Users
collaborators=$(curl \
  --header "Authorization: Bearer $githubToken" \
  --header "Accept: application/vnd.github.v3+json" \
  --request GET \
  "https://api.github.com/repos/${githubRepo}/collaborators" \
  | jq -r '.[].login')


# Get Repo Teams
teams=$(curl \
  --header "Authorization: Bearer $githubToken" \
  --header "Accept: application/vnd.github.v3+json" \
  --request GET \
  "https://api.github.com/repos/${githubRepo}/teams" \
  | jq -r '.[].slug')


# Create output variables
echo "::set-output name=collaborators::$collaborators"
echo "::set-output name=teams::$teams"

access_token=$(curl --location --request POST 'https://api.getport.io/v1/auth/access_token' --header 'Content-Type: application/json' --data-raw "{
	\"clientId\": \"$portClientId\",
	\"clientSecret\": \"$portClientSecret\"
}" | jq '.accessToken' | sed 's/"//g')

echo "Validating if a blueprint with the identifier $blueprintIdentifier identifier exists in Port"

response=$(curl -X 'GET' \
  "https://api.getport.io/v1/blueprints/$blueprintIdentifier" \ 
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $access_token" \
  --write-out '%{http_code}' \
  --silent \
  --output /dev/null)

echo "Get blueprint response code: $response"

if [ $response -eq 200 ]; then
  echo "Blueprint with the identifier $blueprintIdentifier exists in Port"
elif [ $response -eq 404 ]; then
  curl -X 'POST' \
    'https://api.getport.io/v1/blueprints' \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $access_token" \
    -d "{
        \"identifier\": \"$blueprintIdentifier\",
        \"title\": \"$blueprintIdentifier\",
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
          \"required\": [
          ]
        },
        \"calculationProperties\": {},
        \"mirrorProperties\": {},
        \"relations\": {}
      }"
else
  echo "Something went wrong fetching $blueprintIdentifier blueprint from Port with status code $response"
fi
