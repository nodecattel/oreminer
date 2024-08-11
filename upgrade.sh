#!/bin/bash

echo -e "\033[0;32m"
cat << "EOF"
█▀█ █▀█ █▀▀ █▀▄▀█ █ █▄░█ █▀▀ █▀█
█▄█ █▀▄ ██▄ █░▀░█ █ █░▀█ ██▄ █▀▄ ORE V2 - Upgrade
EOF
echo -e "Upgrading ORE CLI\033[0m"

# Exit script if any command fails
set -e

# Prompt to select environment (mainnet, jito, or panda-optimized-cores)
echo -e "\033[0;32m"
read -p "Choose Solana network (m for mainnet, j for jito dynamic tip, p for panda-opti-cores): " env_choice
echo -e "\033[0m"  # Reset color
case "$env_choice" in
    [Mm]*)
        echo "Switching to 'mainnet'..."
        solana config set --url https://api.mainnet-beta.solana.com
        REPO_URL="https://github.com/regolith-labs/ore-cli"
        ORE_CLI_DIR="$HOME/oreminer/ore-cli"
        ;;
    [Jj]*)
        echo "Switching to 'jito dynamic tip'..."
        solana config set --url https://api.mainnet-beta.solana.com
        REPO_URL="https://github.com/nodecattel/ore-cli-jito.git"
        ORE_CLI_DIR="$HOME/oreminer/ore-cli-jito"
        ;;
    [Pp]*)
        echo "Switching to 'panda-opti-cores'..."
        solana config set --url https://api.mainnet-beta.solana.com
        REPO_URL="https://github.com/JustPandaEver/ore-cli.git"
        ORE_CLI_DIR="$HOME/oreminer/ore-cli-panda"
        ;;
    *)
        echo "Invalid choice. Staying on current environment."
        exit 1
        ;;
esac

# Determine the default branch name
DEFAULT_BRANCH=$(git ls-remote --symref "$REPO_URL" HEAD | awk '/^ref:/ {print $2}' | sed 's/refs\/heads\///')

# Clone or update ORE-CLI from source
if [ -d "$ORE_CLI_DIR" ]; then
    echo "Updating ORE-CLI repository..."
    cd $ORE_CLI_DIR
    git remote set-url origin "$REPO_URL"
    git fetch origin
    git checkout $DEFAULT_BRANCH
    git pull origin $DEFAULT_BRANCH
else
    echo "Cloning ORE-CLI repository..."
    mkdir -p $(dirname $ORE_CLI_DIR)
    git clone --branch $DEFAULT_BRANCH "$REPO_URL" $ORE_CLI_DIR
    cd $ORE_CLI_DIR
fi

# Additional steps for mainnet
if [[ "$env_choice" =~ [Mm] ]]; then
    echo "Setting up additional repository for mainnet..."
    cd $HOME/oreminer
    if [ -d "$HOME/oreminer/ore" ]; then
        cd ore
        git remote set-url origin https://github.com/regolith-labs/ore
        git fetch origin
        git checkout master
    else
        git clone https://github.com/regolith-labs/ore.git
        cd ore
        git checkout master
    fi
    cd $ORE_CLI_DIR
fi

# Build the ORE-CLI binary
echo "Building ORE-CLI..."
cargo build --release

# Move the binary to the appropriate location
cp target/release/ore $HOME/.cargo/bin/ore
echo "Ore CLI has been installed from source and updated to the latest version."

# Print the current installed version of Ore CLI
echo "The current installed version of Ore CLI is:"
ore --version
echo -e "\033[0;35m by NodeCattel\033[0m"

# Give execution permission to ore.sh
ORE_SH_PATH="$HOME/oreminer/ore.sh" # Update with the actual path
if [ -f "$ORE_SH_PATH" ]; then
    chmod +x "$ORE_SH_PATH"
    echo "Executable permissions set for ore.sh."
else
    echo "ore.sh does not exist at $ORE_SH_PATH. Please make sure it's in the correct location."
fi

# Optionally prompt the user to run ore.sh for further setup
read -p "Do you wish to start mining? [Y/n] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "Starting mining with the latest ore-cli"
    cd $(dirname "$ORE_SH_PATH") # Change directory to where ore.sh is located
    ./ore.sh mine
else
    echo -e "Upgrade complete. You can start mining manually by running ./ore.sh mine."
fi
