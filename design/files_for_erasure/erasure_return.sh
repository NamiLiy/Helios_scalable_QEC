#!/bin/bash

# Define the CSV file
csv_file="erasure_file_mapping.csv"  # Replace with the actual CSV file name and path

# Define the folders
original_folder="original_folder"
erasure_folder="erasure_folder"

# Function to move a file from source to destination folder
move_file() {
    local source="$1"
    local destination="$2"
    
    if [ -e "$source" ]; then
        mv "$source" "$destination/"
        echo "Moved '$source' to '$destination/'"
    else
        echo "File '$source' does not exist."
    fi
}

# Create the original folder if it doesn't exist
if [ ! -d "$original_folder" ]; then
    mkdir -p "$original_folder"
fi

# Read and parse the CSV file
while IFS=, read -r new_file_location new_file_name; do
    # Check if new_file_location and new_file_name are not empty
    if [ -n "$new_file_location" ] && [ -n "$new_file_name" ]; then
        # Check if the file exists in new_file_location
        if [ -e "$new_file_location/$new_file_name" ]; then
            # Move the file from new_file_location to original_folder
            move_file "$new_file_location/$new_file_name" "$erasure_folder"
        else
            echo "File '$new_file_name' does not exist in '$new_file_location'."
        fi
        
        move_file "$original_folder/$new_file_name" "$new_file_location"
    else
        echo "Empty new_file_location or new_file_name for a file."
    fi
done < "$csv_file"

echo "File moving completed."


