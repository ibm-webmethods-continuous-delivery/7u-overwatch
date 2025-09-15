#!/bin/sh

#
# Copyright IBM Corp. 2025 - 2025
# SPDX-License-Identifier: Apache-2.0
#

repo_dir="$1"
if [ ! -d "$repo_dir/.git" ]; then
    echo "Warning: $repo_dir is not a git repository"
    return 1
fi
# Add repository to git safe directories to avoid ownership issues
git config --global --add safe.directory "$repo_dir"

crtDir=$(pwd)
cd "$repo_dir" || exit 2
# Configure git user based on host wrapper
git config user.name "${GIT_USER_NAME}"
git config user.email "${GIT_USER_MAIL}"

# Set up commit signing and repo config
pub_key="${OVW_PUB_KEY:-$HOME/.ssh/id_rsa.pub}"
prv_key="${OVW_PRV_KEY:-$HOME/.ssh/id_rsa}"
signers_file="${OVN_SIGNERS_FILE:-$HOME/.ssh/allowed_signers}"

if [ ! -f "${pub_key}" ]; then
    ssh-keygen -t rsa -b 4096 -f "${prv_key}" -P "" -C "${GIT_USER_MAIL}_$(date +%y-%m-%d)"
    echo "============================="
    echo "New ssh key generated in the file ${prv_key}"
    awk '{ print $3 " " $1 " " $2 }' "${pub_key}" >> "${signers_file}"
    echo "Now load the public key in GitHub for identification AND signing"
    echo "============================="
fi 

git config commit.gpgSign true
git config user.signingkey "$pub_key"
git config gpg.ssh.allowedSignersFile "${signers_file}"
# Optionally, set GPG program to ssh-keygen if using SSH keys for signing (advanced, may require extra setup)
# git config gpg.program "ssh-keygen"
git config core.eol lf
git config core.autocrlf input
git config core.fileMode false
echo "Git config set for ${repo_dir}"

cd "${crtDir}" || exit 3