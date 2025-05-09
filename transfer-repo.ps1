# -----------------------------
# GitHub Repository Transfer Script (PowerShell Version)
# -----------------------------

# Input Variables
$SourceOwner = "mtaoufik"           # Current owner of the repository (username or organization)
$RepoName = "azure-services-powershell"            # Name of the repository to transfer
$DestinationOwner = "taoufikmohamed"          # New owner's username or organization

# Get GitHub Token from Environment Variable
$GitHubToken = $env:GITHUB_TOKEN
if (-not $GitHubToken) {
    Write-Host "Error: GITHUB_TOKEN environment variable is not set."
    Write-Host "Please set the GitHub Personal Access Token using:"
    Write-Host "`$env:GITHUB_TOKEN = 'your_personal_access_token'"
    exit 1
}

# GitHub API URL
$GitHubApiUrl = "https://api.github.com/repos/$SourceOwner/$RepoName/transfer"

# Function to Initiate Repository Transfer
function Transfer-Repository {
    Write-Host "Initiating transfer of repository '$RepoName' from '$SourceOwner' to '$DestinationOwner'..."

    # Prepare the JSON payload
    $Payload = @{
        new_owner = $DestinationOwner
    } | ConvertTo-Json -Depth 1

    # Make the API request
    $Response = Invoke-RestMethod -Uri $GitHubApiUrl `
        -Method Post `
        -Headers @{
            "Authorization" = "token $GitHubToken"
            "Accept" = "application/vnd.github.surtur-preview+json"
        } `
        -Body $Payload

    # Check the response
    if ($Response -and $Response.id) {
        Write-Host "Repository transfer initiated successfully!"
        Write-Host "The new owner ($DestinationOwner) must accept the transfer for it to complete."
    } else {
        Write-Host "Failed to initiate repository transfer. Response:"
        Write-Host $Response | ConvertTo-Json -Depth 10
    }
}

# Function to Check Transfer Status
function Check-TransferStatus {
    Write-Host "Checking transfer status for repository '$RepoName'..."

    # Make the API request to get repository details
    $Response = Invoke-RestMethod -Uri "https://api.github.com/repos/$SourceOwner/$RepoName" `
        -Method Get `
        -Headers @{
            "Authorization" = "token $GitHubToken"
        }

    # Check the state of the repository
    if ($Response -and $Response.state -eq "transferred") {
        Write-Host "The repository transfer has been completed successfully!"
    } else {
        Write-Host "The repository transfer is still pending or failed. Response:"
        Write-Host $Response | ConvertTo-Json -Depth 10
    }
}

# Main Script Execution