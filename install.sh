#!/bin/bash

# Ensure we're using the correct shell
source ~/.profile

# Detect OS and set profile file accordingly
OS="$(uname)"
if [[ "$OS" == "Darwin" ]]; then
    PROFILE_FILE=~/.profile
else
    PROFILE_FILE=~/.bashrc
fi
source "$PROFILE_FILE"

# Install dependencies
sudo apt update
sudo apt install -y python3-mpmath python3-numpy python3-sympy python3-unicodedata2 unicode-data

# Install Solana CLI if not already installed
if ! command -v solana &> /dev/null; then
    echo "Installing Solana CLI..."
    sh -c "$(curl -sSfL https://release.solana.com/v1.7.14/install)"
else
    echo "Solana CLI is already installed. Skipping installation."
fi

# Check if wallet exists and generate keypair if not
if [ ! -f "$HOME/.config/solana/id.json" ]; then
    echo "Generating new Solana keypair..."
    solana-keygen new --outfile "$HOME/.config/solana/id.json"
else
    echo "Existing wallet found. Skipping key generation."
fi

# Select Solana network
read -p "Choose Solana network (m for mainnet, d for devnet): " network
if [[ "$network" == "m" ]]; then
    solana config set --url https://api.mainnet-beta.solana.com
elif [[ "$network" == "d" ]]; then
    solana config set --url https://api.devnet.solana.com
else
    echo "Invalid choice. Defaulting to mainnet."
    solana config set --url https://api.mainnet-beta.solana.com
fi

# Display Solana config
solana config get

# Update ORE-CLI repository
echo "Updating ORE-CLI repository..."
cd "$HOME/oreminer"
git config pull.rebase false  # You can set this globally if you prefer
git pull origin master

if [[ $? -ne 0 ]]; then
    echo "Pull failed. Ensure you are on the correct branch and repository is clean."
    exit 1
fi

# Build the ORE-CLI with cargo
echo "Building ORE-CLI with cargo..."
cargo build --release

if [[ $? -ne 0 ]]; then
    echo "Cargo build failed. Ensure you have Rust installed and try again."
    exit 1
fi

# Final message
echo "Installation or update process completed. ORE-CLI is ready to use."