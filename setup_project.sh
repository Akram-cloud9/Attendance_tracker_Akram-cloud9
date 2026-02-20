#!/bin/bash

# ==============================
# STUDENT ATTENDANCE PROJECT FACTORY
# ==============================

# --- 1. CHECK INPUT ---
if [ -z "$1" ]; then
    echo "Error: You must provide a GitHub username."
    echo "Usage: ./setup_project.sh <github_username>"
    exit 1
fi

USER_NAME=$1
PROJECT_DIR="attendance_tracker_${USER_NAME}"
ARCHIVE_NAME="${PROJECT_DIR}_archive.tar.gz"

# --- 2. SETUP THE TRAP (Process Management) ---
cleanup() {
    echo -e "\n\nProcess interrupted! Cleaning up..."

    if [ -d "$PROJECT_DIR" ]; then
        tar -czf "$ARCHIVE_NAME" "$PROJECT_DIR"
        rm -rf "$PROJECT_DIR"
        echo "Backup created: $ARCHIVE_NAME"
        echo "Incomplete directory removed."
    fi

    exit 1
}

trap cleanup SIGINT

# --- Prevent overwriting existing directory ---
if [ -d "$PROJECT_DIR" ]; then
    echo "Error: Directory already exists."
    exit 1
fi

# --- 3. CREATE DIRECTORY ARCHITECTURE ---
echo "Creating project structure for user: $USER_NAME"

mkdir -p "$PROJECT_DIR/Helpers" || exit 1
mkdir -p "$PROJECT_DIR/reports" || exit 1

# Ensure required source files exist before copying
for file in attendance_checker.py assets.csv config.json reports.log; do
    if [ ! -f "$file" ]; then
        echo "Error: Required file '$file' not found in current directory."
        cleanup
    fi
done

cp attendance_checker.py "$PROJECT_DIR/" || cleanup
cp assets.csv "$PROJECT_DIR/Helpers/" || cleanup
cp config.json "$PROJECT_DIR/Helpers/" || cleanup
cp reports.log "$PROJECT_DIR/reports/" || cleanup

echo "Files copied successfully."

# --- 4. ENVIRONMENT HEALTH CHECK ---
echo "Checking system requirements..."

if python3 --version >/dev/null 2>&1; then
    echo "Success: Python 3 is installed."
else
    echo "Warning: Python 3 is NOT installed."
fi

# --- 5. DYNAMIC CONFIGURATION ---
echo "Do you want to update the configuration thresholds? (y/n)"
read -r response

if [[ "$response" == "y" || "$response" == "Y" ]]; then

    read -p "Enter new Warning threshold (default 75): " new_warn
    read -p "Enter new Failure threshold (default 50): " new_fail

    # Validate numeric input
    if ! [[ "$new_warn" =~ ^[0-9]+$ ]] || ! [[ "$new_fail" =~ ^[0-9]+$ ]]; then
        echo "Error: Thresholds must be numeric values."
        cleanup
    fi

    # Update JSON using sed (in-place editing)
    sed -i '' "s/\"warning_threshold\": [0-9]*/\"warning_threshold\": $new_warn/" "$PROJECT_DIR/Helpers/config.json"
    sed -i '' "s/\"failure_threshold\": [0-9]*/\"failure_threshold\": $new_fail/" "$PROJECT_DIR/Helpers/config.json"

    echo "Configuration updated successfully."
fi

# --- 6. STRUCTURE VALIDATION ---
if [ -f "$PROJECT_DIR/attendance_checker.py" ] && \
   [ -f "$PROJECT_DIR/Helpers/assets.csv" ] && \
   [ -f "$PROJECT_DIR/Helpers/config.json" ] && \
   [ -f "$PROJECT_DIR/reports/reports.log" ]; then
    echo "Directory structure validated successfully."
else
    echo "Error: Directory structure validation failed."
    cleanup
fi

echo "Setup complete! Your new project folder is: $PROJECT_DIR"

