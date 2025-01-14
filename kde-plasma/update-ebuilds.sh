#!/bin/bash

# Set IFS to handle spaces in directory names
IFS=$'\n'

# Counter for processed directories
count=0

# Loop through each directory
for dir in */; do
    # Check if directory contains any ebuilds
    if ls "$dir"/*.ebuild 1> /dev/null 2>&1; then
        cd "$dir"
        echo "Processing directory: $dir"
        for ebuild in *.ebuild; do
            echo "Running manifest for: $ebuild"
            ebuild "$ebuild" manifest clean
        done
        cd ..
        ((count++))
    fi
done

echo "Total directories processed: $count" 