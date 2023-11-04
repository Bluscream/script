import argparse
import logging
from time import sleep
from github import Github, GithubException, Repository
from os import environ

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Create the parser
parser = argparse.ArgumentParser(description='Manage GitHub repositories.')
parser.add_argument('--user', action='store_true', default=True)
parser.add_argument('--orgs', action='store_true', default=True)
parser.add_argument('--list', type=str, help='File path')
parser.add_argument('--merge', action='store_true')
parser.add_argument('--public', action='store_true')
parser.add_argument('--private', action='store_true')
parser.add_argument('--archive', action='store_true')
parser.add_argument('--unarchive', action='store_true')
parser.add_argument('--delete', action='store_true')
parser.add_argument('--token', type=str, help='GitHub token')

# Parse the arguments
args = parser.parse_args()

if args.public and args.private:
    logging.error("Cannot make public and private at the same time!")
    exit(1)
elif args.archive and args.unarchive:
    logging.error("Cannot archive and unarchive at the same time!")
    exit(1)
elif args.delete:
    really_delete = input("Are you sure you want to delete all repos? [y/n]")
    # todo: handle input

# Authenticate with GitHub
token = args.token if args.token else environ.get('GITHUB_TOKEN')
if not token:
    logging.warn("No token provided! Use `--token <TOKEN>` switch or GITHUB_TOKEN environment variable")
    token = input("Enter Github token to use:")
    if not token: exit(1)
g = Github(token)
user = g.get_user()
logging.info(f'Logged in as \"{user.name}\" ({user.email})')

list_file = open(args.list, 'w') if args.list else None
# Get user and organizations repositories
user_repos = user.get_repos()
orgs = user.get_orgs()
orgs_repos = [repo for org in orgs for repo in org.get_repos()]

# Define actions
def mergePRs(repo: Repository):
    if repo.archived:
        logging.warning(f'The repository {repo_name(repo)} is archived. Skipping...')
        return
    pulls = repo.get_pulls()
    logging.info(f'Found {pulls.totalCount} pull requests in repo: {repo_name(repo)}')
    for pull in pulls:
        if pull.mergeable:
            pull.merge()
            logging.info(f'Merged pull request {pull.number} in repo: {repo_name(repo)}')
        else:
            pull.edit(state='closed')
            logging.info(f'Closed pull request {pull.number} in repo: {repo_name(repo)}')
        sleep(2)

def makePublic(repo: Repository):
    if not repo.private:
        repo.edit(private=False)
        logging.info(f'Made repo {repo_name(repo)} public')

def makePrivate(repo: Repository):
    if repo.private:
        repo.edit(private=True)
        logging.info(f'Made repo {repo_name(repo)} private')

def archiveRepo(repo: Repository):
    if not repo.archived:
        repo.edit(archived=True)
        logging.info(f'Archived repo {repo_name(repo)}')

def unarchiveRepo(repo: Repository):
    if repo.archived:
        repo.edit(archived=False)
        logging.info(f'Unarchived repo {repo_name(repo)}')

def deleteRepo(repo: Repository):
    repo.delete()
    logging.info(f'Deleted repo {repo_name(repo)}')

def repo_name(repo: Repository):
    return f"\"{repo.owner.login}/{repo.name}\""

# Iterate over all repositories
def process_repos(repos: Repository):
    ok = 0;failed = 0
    for repo in repos:
        try:
            logging.debug(f"Processing repository {ok+failed+1} {repo_name(repo)}")
            if list_file:
                list_file.writelines([f'{repo_name(repo)}'])
            if args.merge:
                mergePRs(repo)
            if args.public:
                makePublic(repo)
            if args.private:
                makePrivate(repo)
            if args.archive:
                archiveRepo(repo)
            if args.unarchive:
                unarchiveRepo(repo)
            if args.delete:
                deleteRepo(repo)
            ok += 1
        except GithubException as e:
            failed += 1
            logging.error(f'An error occurred while processing repository {repo_name(repo)}: {e.status} {e.data}')
            if list_file: list_file.writelines([f'{repo_name(repo)} - {e.status} {e.data}'])
        except Exception as e:
            failed += 1
            logging.error(f'An error occurred while processing repository {repo_name(repo)}: {e}')
            if list_file: list_file.writelines([f'{repo_name(repo)} - {e}'])
        sleep(.5)
    logging.info(f'Processed {ok} / {ok+failed} repos')
    return (ok, failed)

ok = 0;failed = 0
if args.user:
    _ok, _failed = process_repos(user_repos)
    ok += _ok;failed += _failed
if args.orgs:
    _ok, _failed = process_repos(orgs_repos)
    ok += _ok;failed += _failed

logging.info(f'Finished processing {ok} / {ok+failed} repos')
