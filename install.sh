#!/bin/bash
# ez-hpc Installation Script

set -e

# --- Helper Functions ---
print_step() {
    echo -e "\n\033[1;34m==>\033[0m \033[1m$1\033[0m"
}

print_success() {
    echo -e "\033[1;32m  ✓ $1\033[0m"
}

print_warning() {
    echo -e "\033[1;33m  ! $1\033[0m"
}

# Get the absolute path to the directory where this script is located
REPO_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
SRC_DIR="$REPO_DIR/src"
CONFIG_DIR="$REPO_DIR/config"

echo "========================================================"
echo "         ez-hpc Installer"
echo "========================================================"
echo "Installing from: $REPO_DIR"

# --- Step 1: Setup User Configuration ---
print_step "Setting up configuration..."

DEFAULT_CONFIG="$CONFIG_DIR/default_configs.sh"
USER_CONFIG="$CONFIG_DIR/user_configs.sh"

if [ ! -f "$DEFAULT_CONFIG" ]; then
    echo "Error: Default configuration file not found at $DEFAULT_CONFIG"
    exit 1
fi

if [ -f "$USER_CONFIG" ]; then
    print_warning "User config already exists at $USER_CONFIG"
    echo "    Skipping copy to avoid overwriting your settings."
else
    cp "$DEFAULT_CONFIG" "$USER_CONFIG"
    print_success "Created user config at $USER_CONFIG"
    echo "    You should edit this file to set your specific cluster defaults."
fi

# --- Step 2: Update PATH in .bashrc ---
print_step "Updating \$PATH in .bashrc..."

BASHRC="$HOME/.bashrc"
EXPORT_LINE="export PATH=\"\$PATH:$SRC_DIR\""

# Check if path is already in .bashrc (loosely)
if grep -q "$SRC_DIR" "$BASHRC"; then
    print_warning "Path seems to be already present in $BASHRC"
    echo "    Skipping update."
else
    echo "" >> "$BASHRC"
    echo "# ez-hpc tools" >> "$BASHRC"
    echo "$EXPORT_LINE" >> "$BASHRC"
    print_success "Added $SRC_DIR to $BASHRC"
    echo "    Please run 'source ~/.bashrc' or restart your terminal to apply changes."
fi

# --- Step 3: Jupyter Environment Setup ---
print_step "Jupyter Environment Setup"

read -p "Do you want to set up the 'jupyter' conda environment? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ENV_NAME="jupyter"
    ENV_FILE="$REPO_DIR/jupyter_env/environment.yml"

    # Check if conda is installed
    if ! command -v conda &> /dev/null; then
        echo "Error: 'conda' command not found. Please install Conda/Mamba first."
        exit 1
    fi

    # Check if environment exists
    if conda env list | grep -q "^$ENV_NAME "; then
        print_warning "Environment '$ENV_NAME' already exists."
        read -p "Do you want to update it with any missing packages from environment.yml? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Updating '$ENV_NAME'..."
            conda env update -n "$ENV_NAME" -f "$ENV_FILE"
            print_success "Environment updated."
        else
            echo "Skipping update."
        fi
    else
        echo "Creating '$ENV_NAME' environment from $ENV_FILE..."
        conda env create -f "$ENV_FILE"
        print_success "Environment '$ENV_NAME' created successfully."
    fi
else
    echo "Skipping Jupyter environment setup."
fi

echo "========================================================"
echo -e "\033[1;32mInstallation Complete!\033[0m"
echo "1. Edit config/user_configs.sh to match your cluster."
echo "2. Run 'source ~/.bashrc' to enable the commands."
echo "========================================================"

