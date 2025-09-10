# IWCD Overwatch

This repository is provided as a convenience to manage one or more repositories in this framework at once.

## Quick Start

Immediately after cloning this repository, consider the following steps:

1. The managed repositories are specified in the csv file `runconfigs\iwcd-overwatch\scripts\repos.csv`. This file is gitignored, create a new one by copying over `runconfigs\iwcd-overwatch\scripts\allRepos.csv` and eventually filter for the repositories of interest.
2. Add in the folder `runconfigs\iwcd-overwatch\local\.ssh` your ssh keys to interact with Github. We recommend to generate and use ad-hoc keys for this purpose.
3. Copy the file EXAMPLE.env into .env and modify to match your username and email from GitHub.
4. Use the container `runconfigs\iwcd-overwatch` to manage the repositories.

    - Run the file `run.bat`
    - Open a shell using `shell.bat`
    - change dir to `~/s` and run `./fetch-all.sh`. Consistently use this tool to sync from origin
    - do your work
    - in the end destroy the container using `down.bat`

Remember that all files ar expected to have unix end lines, clone accordingly.
