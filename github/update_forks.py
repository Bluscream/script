from github import Github
import time
from os import environ

# First create a Github instance using an access token
g = Github(environ.get('GITHUB_TOKEN'))

# Then get your user
user = g.get_user()

# Get all your forked repos
for repo in user.get_repos():
    if repo.fork:
        # Get the base repo
        base_repo = repo.parent

        # Create a pull request for each branch
        for branch in base_repo.get_branches():
            try:
                base = base_repo.default_branch
                head = f"{user.login}:{branch.name}"
                title = f"Update from base repo to forked one for branch {branch.name}"
                body = "This is an automated pull request."
                base_repo.create_pull(title=title, body=body, base=base, head=head)
                print(f"Created pull request for {repo.name} from {base} to {branch.name}")
            except Exception as e:
                print(f"Failed to create pull request for {repo.name} from {base} to {branch.name}: {e}")