#!/bin/bash
source ~/.profile

echo -e "\033[0;32m"
cat << "EOF"
█▀█ █▀█ █▀▀ █▀▄▀█ █ █▄░█ █▀▀ █▀█
█▄█ █▀▄ ██▄ █░▀░█ █ █░▀█ ██▄ █▀▄ V2 - 1.0.0-alpha
EOF
echo -e "Version 0.2.0 - Ore Cli installer + PMC ui"
echo -e "Made by NodeCattel & All the credits to HardhatChad\033[0m"

# Exit script if any command fails
set -e

# Install Rust and Cargo
echo "Installing Rust and Cargo..."
curl https://sh.rustup.rs -sSf | sh -s -- -y

# Ensure Cargo is in the PATH
source $HOME/.cargo/env

# Install build tools (Ubuntu/Debian specific)
echo "Installing build tools..."
sudo apt update
sudo apt install -y build-essential

# Install Solana CLI
echo "Installing Solana CLI..."
sh -c "$(curl -sSfL https://release.solana.com/v1.18.4/install)"

# Ensure Solana is in the PATH
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.bashrc

# Function to clone or update a repository
clone_or_update_repo() {
    local repo_url=$1
    local repo_dir=$2
    if [ -d "$repo_dir" ]; then
        echo "Updating repository $repo_dir..."
        cd "$repo_dir"
        git fetch
        git pull
        cd ..
    else
        echo "Cloning repository $repo_url..."
        git clone "$repo_url"
    fi
}

# Install ORE-CLI tags/1.0.0-alpha
cargo install ore-cli@1.0.0-alpha
echo "Ore CLI has been updated to the latest version."

# Prompt to switch to devnet
read -p "Do you wish to switch to 'devnet' environment for testing? [Y/n] " devnet_answer
if [[ "$devnet_answer" =~ ^[Yy]$ ]]; then
    echo "Switching to 'devnet'..."
    solana config set --url https://api.devnet.solana.com
    if [ -f "$HOME/.config/solana/id.json" ]; then
        echo "Existing wallet found. Skipping key generation."
    else
        solana-keygen new
    fi
    solana airdrop 1
    echo "You are now on 'devnet'. To switch back to 'mainnet', run:"
    echo "solana config set --url https://api.mainnet-beta.solana.com"
else
    echo "Staying on 'mainnet'."
fi

# Print the current installed version of Ore CLI
echo "The current installed version of Ore CLI is:"
ore --version

# Give execution permission to ore.sh
ORE_SH_PATH="$HOME/oreminer/ore.sh" # Update with the actual path
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
