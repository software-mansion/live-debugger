#!/bin/bash

# Function to copy a specific icon
copy_icon() {
    local icon_name="$1"
    local -a src_dest=(
        "../heroicons/optimized/24/outline/ ./assets/icons/heroicons/optimized/24/outline/"
        "../heroicons/optimized/24/solid/ ./assets/icons/heroicons/optimized/24/solid/"
        "../heroicons/optimized/20/solid/ ./assets/icons/heroicons/optimized/20/solid/"
        "../heroicons/optimized/16/solid/ ./assets/icons/heroicons/optimized/16/solid/"
    )

    local file_name="${icon_name}.svg"
    local copied=false

    for pair in "${src_dest[@]}"; do
        read src_dir dest_dir <<< "$pair"
        local src="${src_dir}${file_name}"
        local dest="${dest_dir}${file_name}"

        if [ -f "$src" ]; then
            mkdir -p "$(dirname "$dest")"
            cp "$src" "$dest"
            echo "Copied: $src -> $dest"
            copied=true
        fi
    done

    if [ "$copied" = false ]; then
        echo "Error: Icon '$icon_name' not found in any source directory"
    fi
}

# Get icon name from user input
read -p "Enter icon name (without .svg extension): " icon_name

# Copy the icon
copy_icon "$icon_name"
