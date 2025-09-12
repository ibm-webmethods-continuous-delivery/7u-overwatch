#!/bin/sh

#
# Copyright IBM Corp. 2025 - 2025
# SPDX-License-Identifier: Apache-2.0
#

# fetch-all.sh - POSIX compliant script to manage git repositories in the organization
# https://github.com/orgs/ibm-webmethods-continuous-delivery
# This script reads repos.csv, soft synchronizes the local repositories and highlights local updates

set -e  # Exit on error

# Get the directory where this script is located
BASE_DIR=~/o                        # Convention - this repo is mounted to ~/o inside the container
SCRIPT_DIR=~/s                      # Convention - scripts are mounted in ~/s inside the container
REPO_CSV="$SCRIPT_DIR/repos.csv"    # Initially single column

# Convention - we are only looking at repositories in this organization
BASE_REPO_URL="git@github.com:ibm-webmethods-continuous-delivery"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to setup git user config for a repository
setup_git_config() {
    local repo_dir="$1"
    if [ ! -d "$repo_dir/.git" ]; then
        log "Warning: $repo_dir is not a git repository"
        return 1
    fi
    # Add repository to git safe directories to avoid ownership issues
    git config --global --add safe.directory "$repo_dir"
    cd "$repo_dir"
    # Configure local git user based on host wrapper
    git config user.name "${GIT_USER_NAME}"
    git config user.email "${GIT_USER_MAIL}"
    # Set up commit signing and repo config
    local pub_key="${OVW_PUB_KEY:-$HOME/.ssh/id_rsa.pub}"
    local prv_key="${OVW_PRV_KEY:-$HOME/.ssh/id_rsa}"
    git config commit.gpgSign true
    git config user.signingkey "$prv_key"
    # Optionally, set GPG program to ssh-keygen if using SSH keys for signing (advanced, may require extra setup)
    # git config gpg.program "ssh-keygen"
    git config core.eol lf
    git config core.autocrlf input
    git config core.fileMode false
    log "Git config set for $repo_dir"
}

# Function to check for local changes and unpushed commits
check_local_changes() {
    local repo_path="$1"
    local repo_name="$2"
    
    cd "$repo_path"
    
    # Check if we're in a git repository
    if [ ! -d ".git" ]; then
        return 0
    fi
    
    local has_issues=0
    local status_output=""
    
    # Check for uncommitted changes (staged and unstaged)
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        status_output="${status_output}\n    - Uncommitted changes detected"
        has_issues=1
    fi
    
    # Check for untracked files
    if [ -n "$(git ls-files --others --exclude-standard)" ]; then
        status_output="${status_output}\n    - Untracked files present"
        has_issues=1
    fi
    
    # Check for unpushed commits
    local current_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')"
    if [ -n "$current_branch" ] && [ "$current_branch" != "HEAD" ]; then
        # Check if branch has upstream
        if git rev-parse --verify "@{upstream}" > /dev/null 2>&1; then
            local unpushed_count="$(git rev-list --count "@{upstream}..HEAD" 2>/dev/null || echo '0')"
            if [ "$unpushed_count" -gt 0 ]; then
                status_output="${status_output}\n    - $unpushed_count unpushed commit(s) on branch '$current_branch'"
                has_issues=1
            fi
        else
            # Branch has no upstream, check if it has any commits
            local commit_count="$(git rev-list --count HEAD 2>/dev/null || echo '0')"
            if [ "$commit_count" -gt 0 ]; then
                status_output="${status_output}\n    - Branch '$current_branch' has no upstream (${commit_count} local commit(s))"
                has_issues=1
            fi
        fi
    fi
    
    # If there are issues, display them prominently
    if [ "$has_issues" -eq 1 ]; then
        echo ""
        echo "🚨 =================================="
        echo "🚨 LOCAL CHANGES DETECTED: $repo_name"
        echo "🚨 =================================="
        printf "%b" "$status_output"
        echo ""
        echo "🚨 =================================="
        echo ""
    fi
    
    return $has_issues
}

# Function to clone or update a repository
fetch_repository() {
    local repo_name="$1"
    local url="${BASE_REPO_URL}/${repo_name}"
    local relative_folder="${BASE_DIR}/r"
    
    # Normalize the relative folder path
    local repo_path="${relative_folder}/${repo_name}"

    if [ ! -d "${BASE_DIR}/runconfigs" ]; then
      log "Warning: BASE_DIR has not been resolved correctly! BASE_DIR = ${BASE_DIR}"
      return 1
    fi
    
    log "Processing repository: $repo_name"
    
    # Ensure parent directory exists
    if [ ! -d "$relative_folder" ]; then
        log "Creating parent directory: $relative_folder"
        mkdir -p "$relative_folder"
    fi
    
    if [ -d "$repo_path" ]; then
        # Repository exists, fetch latest
        log "Repository exists, fetching latest changes..."
        cd "$repo_path"
        
        # Verify it's a git repository
        if [ ! -d ".git" ]; then
            log "Error: $repo_path exists but is not a git repository"
            return 2
        fi
        
        # Setup git config
        setup_git_config "$repo_path"
        
        # Fetch all remotes
        git fetch --all --prune
        
        # Get current branch
        current_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
        
        if [ "$current_branch" = "unknown" ] || [ -z "$current_branch" ]; then
            log "Warning: Could not determine current branch, skipping pull"
        else
            # Update current branch if it has an upstream
            if git rev-parse --verify "@{upstream}" > /dev/null 2>&1; then
                log "Updating branch $current_branch..."
                git pull --ff-only
            else
                log "No upstream configured for branch $current_branch, skipping pull"
            fi
        fi
        
        # Check for local changes after update
        check_local_changes "$repo_path" "$repo_name"
        
        log "Successfully updated $repo_name"
    else
        # Repository doesn't exist, clone it
        log "Repository doesn't exist, cloning..."
        
        # Ensure parent directory exists before cloning
        if [ ! -d "$relative_folder" ]; then
            log "Creating parent directory: $relative_folder"
            mkdir -p "$relative_folder"
        fi
        
        cd "$relative_folder"
        
        if git clone "$url" "$repo_name"; then

            log "Successfully cloned $repo_name"

            
            # Setup git config for the newly cloned repository
            setup_git_config "$repo_path"
            
            # Check for any local changes (shouldn't be any for fresh clone, but just in case)
            check_local_changes "$repo_path" "$repo_name"
        else
            log "Error: Failed to clone $repo_name from $url"
            return 3
        fi
    fi
}

# Main execution
main() {
    # Check if repos.csv exists
    if [ ! -f "$REPO_CSV" ]; then
        log "Error: Repository inventory file not found: $REPO_CSV"
        exit 1
    fi

    log "Starting fetch-all script..."
    
    local total_processed=0
    
    # Read CSV file and process each repository
    # Skip header line and process each repository
    tail -n +2 "$REPO_CSV" | while IFS=',' read -r repo_name ; do
        # Skip empty lines
        if [ -z "$repo_name" ] ; then
            continue
        fi
        
        total_processed=$((total_processed + 1))
        
        if ! fetch_repository "$repo_name"; then
            # Continue with other repositories instead of exiting
            log "============= WARNING: Error processing repository $repo_name"
        fi

    done
    
    log "Fetch-all script completed, processed $total_processed repositories"
}

# Run main function
main "$@"
