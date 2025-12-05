#!/bin/bash

# List subfolders so user can choose
echo "Select what to commit:"
echo "1) Commit ALL changes"
echo "2) Commit ONLY a specific folder"
read -p "Enter choice (1 or 2): " choice

commit_path="."

if [ "$choice" == "2" ]; then
    echo "Available folders:"
    # List only directories
    select folder in */; do
        if [ -n "$folder" ]; then
            commit_path="$folder"
            echo "Selected folder: $folder"
            break
        else
            echo "Invalid selection."
        fi
    done
fi

# Ask for commit message
read -p "Commit message: " msg

# Stage files from selected path
git add "$commit_path"

# Commit
git commit -m "$msg"

# Push to main branch
git push -u origin main
