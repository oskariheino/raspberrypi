#!/usr/bin/env bash
# git.sh - interactive commit helper for raspconfigs repo
# Features:
#  - choose to commit all changes or just one folder
#  - shows staged diff before committing
#  - asks for commit message
#  - asks confirmation before pushing to origin main

set -euo pipefail

# Ensure we are in a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: this script must be run from inside a git repository."
  exit 1
fi

# Show short status
echo "Current repo status:"
git status --short
echo

# Ask whether to commit all or a folder
PS3="Choose option: "
options=("Commit ALL changes" "Commit a specific folder" "Abort")
select opt in "${options[@]}"; do
  case $REPLY in
    1)
      commit_path="."
      echo "Will commit ALL changes."
      break
      ;;
    2)
      # List directories only (top-level)
      echo "Select a folder to commit (only top-level directories are shown):"
      mapfile -t dirs < <(find . -maxdepth 1 -mindepth 1 -type d -printf "%f\n" | sort)
      if [ ${#dirs[@]} -eq 0 ]; then
        echo "No subdirectories found."
        exit 1
      fi
      select d in "${dirs[@]}"; do
        if [ -n "${d:-}" ]; then
          commit_path="$d"
          echo "Selected folder: $commit_path"
          break 2
        else
          echo "Invalid selection."
        fi
      done
      ;;
    3)
      echo "Aborting."
      exit 0
      ;;
    *)
      echo "Invalid option."
      ;;
  esac
done

# Check whether there are changes in the chosen path
if [ "$commit_path" = "." ]; then
  changes_count=$(git status --porcelain | wc -l)
else
  # only changes within the selected folder
  changes_count=$(git status --porcelain -- "$commit_path" | wc -l)
fi

if [ "$changes_count" -eq 0 ]; then
  echo "No changes to commit in '$commit_path'. Exiting."
  exit 0
fi

# Stage selected path
if [ "$commit_path" = "." ]; then
  git add .
else
  git add -- "$commit_path"
fi

# Show staged diff summary and full diff for review
echo
echo "=== Staged files (summary) ==="
git --no-pager diff --staged --name-status || true
echo
echo "=== Staged diff (full) ==="
git --no-pager diff --staged || true
echo

# Ask user to continue with commit or abort
read -rp "Proceed to commit the staged changes? (y/N): " proceed
proceed=${proceed:-N}
if [[ ! "$proceed" =~ ^[Yy]$ ]]; then
  echo "Aborting commit. Unstaging changes..."
  git reset --quiet
  exit 0
fi

# Ask for commit message
read -rp "Commit message: " msg
if [ -z "${msg// }" ]; then
  echo "Empty commit message. Aborting and unstaging changes..."
  git reset --quiet
  exit 1
fi

# Commit
git commit -m "$msg"
echo "Commit created."

# Confirm push
read -rp "Push commit to origin main? (y/N): " pushconfirm
pushconfirm=${pushconfirm:-N}
if [[ "$pushconfirm" =~ ^[Yy]$ ]]; then
  # push current branch to origin (you said you always use main, so we push main)
  # If you ever want to auto-detect branch, replace 'main' with:
  # branch=$(git rev-parse --abbrev-ref HEAD); git push -u origin "$branch"
  git push -u origin main
  echo "Pushed to origin main."
else
  echo "Push skipped. Commit is local."
fi

exit 0
