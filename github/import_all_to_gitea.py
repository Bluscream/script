from github import Github
from gitlab import Gitlab
try:
    from gitea import Gitea
    from giteapy import ApiClient
except: pass
from os import environ

# GitHub credentials
github_token = environ.get('GITHUB_TOKEN')

# GitLab credentials
gitlab_url = "https://gitlab.com/"
gitlab_token = environ.get('GITLAB_TOKEN')

# Gitea credentials
gitea_url = "https://git.minopia.de/"
gitea_token = environ.get('GITEA_TOKEN')

# Initialize GitHub API
github_api = Github(github_token)

# Initialize GitLab API
gitlab_api = Gitlab(gitlab_url, private_token=gitlab_token)

# Initialize Gitea API
try: gitea_api = Gitea(url=gitea_url, token=gitea_token)
except: gitea_api = ApiClient(gitea_url)

# Get list of repositories from GitHub
github_repos = github_api.get_user().get_repos()

# Get list of repositories from GitLab
gitlab_repos = gitlab_api.projects.list()

# Iterate over GitHub repositories and import to Gitea
for github_repo in github_repos:
    repo_name = github_repo.name
    gitea_repo = gitea_api.get_repo(repo_name)
    if gitea_repo is None:
        # Repository doesn't exist in Gitea, import it
        gitea_api.create_repo(repo_name)
        # Clone the repository from GitHub and push to Gitea
        gitea_clone_url = gitea_api.get_repo(repo_name).clone_url
        git.Repo.clone_from(github_repo.clone_url, f"/path/to/local/repo/{repo_name}")
        repo = git.Repo(f"/path/to/local/repo/{repo_name}")
        repo.create_remote("gitea", gitea_clone_url)
        repo.remote("gitea").push("--mirror")

# Iterate over GitLab repositories and import to Gitea
for gitlab_repo in gitlab_repos:
    repo_name = gitlab_repo.name
    gitea_repo = gitea_api.get_repo(repo_name)
    if gitea_repo is None:
        # Repository doesn't exist in Gitea, import it
        gitea_api.create_repo(repo_name)
        # Clone the repository from GitLab and push to Gitea
        gitea_clone_url = gitea_api.get_repo(repo_name).clone_url
        git.Repo.clone_from(gitlab_repo.http_url_to_repo, f"/path/to/local/repo/{repo_name}")
        repo = git.Repo(f"/path/to/local/repo/{repo_name}")
        repo.create_remote("gitea", gitea_clone_url)
        repo.remote("gitea").push("--mirror")
