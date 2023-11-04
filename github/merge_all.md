# GitHub Repository Management Script

This script allows you to manage your GitHub repositories using command-line switches. It uses the GitHub API to perform various actions on your repositories, such as merging pull requests, changing repository visibility, archiving/unarchiving repositories, and deleting repositories.

## Usage

You can run the script using Python:

```bash
python merge_all.py --merge --public --token <YOUR_GITHUB_TOKEN>
```

## Command-line Arguments

| Argument | Description |
| --- | --- |
| `--user` | Process user repositories. Default is `True`. |
| `--orgs` | Process organization repositories. Default is `True`. |
| `--list` | File path to write the names of the processed repositories. |
| `--merge` | Merge all pull requests in all repositories. |
| `--public` | Make all repositories public. |
| `--private` | Make all repositories private. |
| `--archive` | Archive all repositories. |
| `--unarchive` | Unarchive all repositories. |
| `--delete` | Delete all repositories. |
| `--token` | GitHub token to use for authentication. |

Note: The `--public` and `--private` switches, and the `--archive` and `--unarchive` switches, cannot be used at the same time.

## Environment Variables

| Variable | Description |
| --- | --- |
| `GITHUB_TOKEN` | GitHub token to use for authentication. This is used if the `--token` switch is not provided. |

## Safety Features

The script includes a prompt to confirm the deletion of all repositories when the `--delete` switch is used. This is to prevent accidental deletion of all repositories.

## Logging

The script includes detailed logging, including the name of the logged-in user, the number of processed repositories, and any errors that occurred. The log messages are printed to the console and can be redirected to a file if needed.

## Requirements

The script requires Python and the `PyGithub` library. You can install `PyGithub` using pip:

```bash
pip install PyGithub
```

## Disclaimer

Please use this script responsibly. The `--delete` switch will delete all your repositories. Always double-check your command-line switches before running the script.