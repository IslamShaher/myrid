#!/bin/bash

# Base URL of your Laravel API
BASE_URL="https://wbu.vhb.temporary.site/api"

# Endpoints to test (key = URI, value = HTTP method)
declare -A endpoints=(
  ["general-setting"]="GET"
  ["get-countries"]="GET"
  ["faq"]="GET"
  ["policies"]="GET"
  ["zones"]="GET"
  ["login"]="POST"
  ["driver/login"]="POST"
  ["ride/list"]="GET"
  ["driver/rides/list"]="GET"
)

for uri in "${!endpoints[@]}"; do
  method=${endpoints[$uri]}
  echo "=== Testing $method $BASE_URL/$uri ==="

  if [ "$method" == "POST" ]; then
    # Send JSON headers + dummy data for POST
    response=$(curl -s -w "\n%{http_code}" -X POST \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      -d '{"email":"test@example.com","password":"123456"}' \
      "$BASE_URL/$uri")
  else
    response=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/$uri")
  fi

  body=$(echo "$response" | head -n -1)
  status=$(echo "$response" | tail -n 1)

  echo "Status: $status"
  echo "Body (first 200 chars):"
  echo "$body" | head -c 200
  echo -e "\n"
done
