#!/bin/bash

# -----------------------------
# Enhanced GitHub Repository Transfer Script
# -----------------------------

# Input Variables
SOURCE_OWNER="current-owner"             # Current owner of the repository (username or organization)
REPO_NAME="repository-name"              # Name of the repository to transfer
DESTINATION_OWNER="new-owner"            # New owner's username or organization
GITHUB_TOKEN="your_personal_access_token" # Your GitHub Personal Access Token

# GitHub API URL
GITHUB_API_URL="https://api.github.com"

# Function to validate prerequisites
validate_inputs() {
  if [[ -z "$GITHUB_TOKEN" ]]; then
    echo "Error: GITHUB_TOKEN is not set. Please provide a valid GitHub Personal Access Token."
    exit 1
  fi
  if [[ -z "$SOURCE_OWNER" || -z "$REPO_NAME" || -z "$DESTINATION_OWNER" ]]; then
    echo "Error: One or more required variables (SOURCE_OWNER, REPO_NAME, DESTINATION_OWNER) are not set."
    exit 1
  fi
}

# Function to initiate repository transfer
transfer_repository() {
  echo "Initiating transfer of repository '$REPO_NAME' from '$SOURCE_OWNER' to '$DESTINATION_OWNER'..."
  
  response=$(curl -s -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.surtur-preview+json" \
    "$GITHUB_API_URL/repos/$SOURCE_OWNER/$REPO_NAME/transfer" \
    -d "{\"new_owner\":\"$DESTINATION_OWNER\"}")

  if echo "$response" | grep -q '"id":'; then
    echo "Repository transfer initiated successfully!"
    echo "The new owner ($DESTINATION_OWNER)