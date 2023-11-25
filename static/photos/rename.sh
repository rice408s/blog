#!/bin/bash

# Define the file extensions to process
extensions=("jpg" "png" "gif" "jpeg" "bmp" "tiff" "webp" "avif" "jxl" "svg" "ico" "heic" "heif")

for ext in "${extensions[@]}"; do
    # Check if there are any files with this extension
    if ls *.$ext *.${ext^^} > /dev/null 2>&1; then
        for file in *.$ext *.${ext^^}; do
            # Check if the file name is already in the desired format
            if [[ ! $file =~ ^[0-9]{4}-[0-9]{1,2}-[0-9]{1,2} ]]; then
                # Get the file's modification date
                date=$(date -r "$file" +"%Y-%m-%d")

                # Get the file's name without extension
                name=$(basename "$file" .$ext)
                name=$(basename "$name" .${ext^^})

                # Construct the new file name
                new_name="${date} ${name}.$ext"

                # Rename the file
                mv -- "$file" "$new_name"
            fi
        done
    fi
done