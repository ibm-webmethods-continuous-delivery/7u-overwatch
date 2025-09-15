# IBM webMethods Continuous Delivery (IWCD) Repositories Overwatch

This repository is provided as a convenience to manage one or more repositories in this framework at once.

## Quick Start

Immediately after cloning this repository, consider the following steps:

1. Go to `runconfigs\iwcd-overwatch` and initialize the local configuration by:

    - copy `EXAMPLE.env` into `.env`
    - edit `.env` and put your username and mail according to Github-s rules
      - Note: it is acceptable to use noreply emails to protect your privacy
    - start the container using `up.bat`
    - start a shell using `shell.bat`
    - run the command `config-repo.sh /h/o` in folder `/h/s/`. This will configure the current repository to follow the required contribution policies.
    - Note that in the folder `runconfigs\iwcd-overwatch\local\.ssh` you now have a new ssh key and the related public keys, but also a `allowed_signers` file used to check the commits signatures. Declare the public ssh key in your GitHub user settings both for authentication and for signature.

2. The managed repositories are specified in the csv file `runconfigs\iwcd-overwatch\scripts\repos.csv`. This file is gitignored, create a new one by copying over `runconfigs\iwcd-overwatch\scripts\allRepos.csv` and eventually filter for the repositories of interest.
3. Use the container `runconfigs\iwcd-overwatch` to manage the repositories.

    - Run the file `up.bat`
    - Open a shell using `shell.bat`
    - change dir to `~/s` and run `./fetch-all.sh`. Consistently use this tool to sync from origin
    - do your work
    - in the end destroy the container using `down.bat`

Remember that all files ar expected to have unix end lines, clone accordingly.

Note that the scripts in this repository are configuring the repostiories to implement the required policies, in particular having cryptographically signed commits. The container is also defining an alias, called `scommit` that stands for `git commit -s`. Signing and "signing-off" are two distinct things, as "signing" is about cryptographically signing the commit and "sign-off" means appending to the commit comment a text line "Signed off by ...". The command `git commit -s` is still required for the append of this signoff line.
