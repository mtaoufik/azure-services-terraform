import requests

# Input Variables
source_username = "work_account_username"
destination_username = "personal_account_username"
github_token = "your_work_account_pat"

# List of repositories to transfer
repositories = ["repo1", "repo2", "repo3"]

for repo in repositories:
    url = f"https://api.github.com/repos/{source_username}/{repo}/transfer"
    headers = {
        "Authorization": f"token {github_token}",
        "Accept": "application/vnd.github.surtur-preview+json"
    }
    payload = {
        "new_owner": destination_username
    }
    response = requests.post(url, json=payload, headers=headers)
    if response.status_code == 202:
        print(f"Transfer of {repo} initiated successfully.")
    else:
        print(f"Failed to transfer {repo}: {response.json()}")