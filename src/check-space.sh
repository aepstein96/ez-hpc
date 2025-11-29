#!/bin/bash
set -euo pipefail

# Function to display help
show_help() {
    cat << EOF
Usage: $0 IN_FOLDER OUT_FOLDER

Check disk space usage for subdirectories.

Positional Arguments:
    IN_FOLDER             Directory to analyze (will check immediate subdirectories). If IN_FOLDER is "store" or "scratch", it will check the entire store or scratch directory.
    OUT_FOLDER            Directory where the output CSV file will be written. By default, it will be written to /lustre/fs4/cao_lab/store/$USER/space_reports/

Options:
    --help, -h         Show this help message

Output:
    Creates a CSV file with folder, file_count, and total_size_bytes columns
    Filename format: YYYY-MM-DD_space_check_IN_FOLDER.csv in the specified OUT_FOLDER directory

Examples:
    $0 /data/my_project /results
    $0 /lustre/fs4/cao_lab/scratch/user/data /lustre/fs4/cao_lab/store/user/logs
EOF
}

# Check for help flag
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    show_help
    exit 0
fi

# Get positional arguments
in_folder="$1"
out_folder="${2:-/lustre/fs4/cao_lab/store/$USER/space_reports/}"
mkdir -p $out_folder

if [ "$in_folder" == "store" ]; then
    in_folder="/lustre/fs4/cao_lab/store/"
elif [ "$in_folder" == "scratch" ]; then
    in_folder="/lustre/fs4/cao_lab/scratch/"
fi
in_folder_name="$(basename "$in_folder")"

output_file="$out_folder/$(date +%Y-%m-%d)_space_check_${in_folder_name}.csv"
temp_file="${output_file}.tmp"

# Validate that folder exists and is a directory
if [ ! -d "$in_folder" ]; then
    echo "Error: Folder '$in_folder' does not exist or is not a directory"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$out_folder"

# Create temporary CSV file with only raw data
echo "Space report for $in_folder_name" > "$temp_file"
echo "subfolder,file_count_raw,total_size_raw" >> "$temp_file"

echo "Analyzing folder: $in_folder"
echo "Output will be written to: $output_file"

# Ensure consistent sorting and byte‐wise du output
export LC_ALL=C

# Find all immediate subdirectories, feed them into parallel
# -j+0 : use one job per CPU
# --lb : line‐buffered output so results stay grouped per dir
find "$in_folder" -mindepth 1 -maxdepth 1 -type d | parallel -j+0 --lb '
  dir="{}"
  # Count files (type f) under the dir
  file_count=$(find "$dir" -type f | wc -l)
  # Total size in bytes
  size_bytes=$(du -sb "$dir" | cut -f1)
  # Get just the folder name (basename)
  folder_name="$(basename "$dir")"
  # Print CSV line with raw data only
  printf "%q,%s,%s\n" "$folder_name" "$file_count" "$size_bytes"
' >> "$temp_file"

# Create final CSV file with human-readable formats and sorting
echo "Space report for $in_folder_name" > "$output_file"
echo "subfolder,file_count,total_size,file_count_raw,total_size_raw" >> "$output_file"

# Process data: sort by raw size (column 3), add human-readable columns, and calculate totals
# Use awk with a more robust approach for handling quotes and external commands
tail -n +3 "$temp_file" | sort -t, -k3,3nr | awk -F, '
{
  # Handle quoted folder names by removing quotes
  subfolder = $1
  gsub(/^["\047]|["\047]$/, "", subfolder)
  
  file_count_raw = $2
  size_raw = $3
  
  # Convert to scientific notation (do this in awk to avoid external calls)
  if (file_count_raw == 0) {
    file_count_sci = "0.0e+00"
  } else {
    exponent = int(log(file_count_raw)/log(10))
    mantissa = file_count_raw / (10^exponent)
    file_count_sci = sprintf("%.1e", file_count_raw)
  }
  
  # For size, we still need numfmt for proper human-readable format
  cmd = "echo " size_raw " | numfmt --to=iec"
  cmd | getline size_human
  close(cmd)
  
  # Output the formatted line
  print subfolder "," file_count_sci "," size_human "," file_count_raw "," size_raw
  
  # Add to totals
  total_files += file_count_raw
  total_bytes += size_raw
}
END {
  # Add totals row
  total_files_sci = sprintf("%.1e", total_files)
  cmd = "echo " total_bytes " | numfmt --to=iec"
  cmd | getline total_size_human
  close(cmd)
  print "TOTAL," total_files_sci "," total_size_human "," total_files "," total_bytes
}
' >> "$output_file"

# Clean up temporary file
rm "$temp_file"

echo "Done — stats written to $output_file"