import requests
import urllib3

# Disable SSL warnings (optional, but recommended when bypassing SSL verification)
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Input Variables
source_username = ""
destination_username = ""
github_token = ""

# List of repositories to transfer
repositories = ["azure-services-terraform", "ml-pipelines", "azure-services-powershell"]


for repo in repositories:
    url = f"https://api.github.com/repos/{source_username}/{repo}/transfer"
    headers = {
        "Authorization": f"token {github_token}",
        "Accept": "application/vnd.github.surtur-preview+json"
    }
    payload = {
        "new_owner": destination_username
    }
    try:
        # Make the API request with SSL verification disabled
        response = requests.post(url, json=payload, headers=headers, verify=False)
        if response.status_code == 202:
            print(f"Transfer of {repo} initiated successfully.")
        else:
            print(f"Failed to transfer {repo}: {response.json()}")
    except requests.exceptions.RequestException as e:
        print(f"Error during transfer of {repo}: {e}")