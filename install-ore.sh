#!/bin/bash
source ~/.profile

echo -e "\033[0;32m"
cat << "EOF"
█▀█ █▀█ █▀▀ █▀▄▀█ █ █▄░█ █▀▀ █▀█
█▄█ █▀▄ ██▄ █░▀░█ █ █░▀█ ██▄ █▀▄
EOF
echo -e "Version 0.1.0 - Ore Cli installer"
echo -e "Made by NodeCattel & All the credits to HardhatChad\033[0m"
# Exit script if any command fails
set -e

# Install Rust and Cargo
echo "Installing Rust and Cargo..."
curl https://sh.rustup.rs -sSf | sh -s -- -y

# Ensure Cargo is in the PATH
source $HOME/.cargo/env

# Install Solana CLI
echo "Installing Solana CLI..."
sh -c "$(curl -sSfL https://release.solana.com/v1.18.4/install)"

# Install Ore CLI
echo "Installing Ore CLI..."
cargo install ore-cli --force

echo "Ore CLI has been updated to the latest version."

# Print the current installed version of Ore CLI
echo "The current installed version of Ore CLI is:"
ore --version

# Give execution permission to ore.sh
ORE_SH_PATH="$HOME/ore/ore.sh" # Update with the actual path
if [ -f "$ORE_SH_PATH" ]; then
    chmod +x "$ORE_SH_PATH"
    echo "Executable permissions set for ore.sh."
else
    echo "ore.sh does not exist at $ORE_SH_PATH. Please make sure it's in the correct location."
fi

# Optionally prompt the user to run ore.sh for further setup
read -p "Do you wish to continue with setting up ore.sh? [Y/n] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "Proceeding with ore.sh setup..."
    "$ORE_SH_PATH"
else
    echo "Setup aborted. Run ore.sh manually to complete setup."
fi

source ~/.profile
