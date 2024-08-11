#!/bin/bash
source ~/.profile

echo -e "\033[0;32m"
cat << "EOF"
█▀█ █▀█ █▀▀ █▀▄▀█ █ █▄░█ █▀▀ █▀█
█▄█ █▀▄ ██▄ █░▀░█ █ █░▀█ ██▄ █▀▄ ORE V2 - 2.1.1 mainnet
EOF
echo -e "Version 0.2.4 - Ore Cli installer"
echo -e "Made by NodeCattel & All the credits to HardhatChad\033[0m"

# Exit script if any command fails
set -e

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)     OS_TYPE=Linux;;
    Darwin*)    OS_TYPE=Mac;;
    *)          OS_TYPE="UNKNOWN:${OS}"
esac

echo "Detected OS: $OS_TYPE"

# Install Rust and Cargo
echo "Installing Rust and Cargo..."
curl https://sh.rustup.rs -sSf | sh -s -- -y

# Ensure Cargo is in the PATH
. "$HOME/.cargo/env"  # For sh/bash/zsh/ash/dash/pdksh
if [ "$SHELL" = "fish" ]; then
    source "$HOME/.cargo/env.fish"
fi

if [ "$OS_TYPE" == "Linux" ]; then
    # Update and upgrade the system
    echo "Updating and upgrading the system..."
    sudo apt update
    sudo apt upgrade -y

    # Install required dependencies
    echo "Installing required dependencies..."
    sudo apt install -y openssl pkg-config libssl-dev
elif [ "$OS_TYPE" == "Mac" ]; then
    # Install Homebrew if not installed
    if ! command -v brew &> /dev/null; then
        echo "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    echo "Installing required dependencies for Mac..."
    brew install openssl pkg-config

    # Set environment variables for OpenSSL if necessary
    export PATH="/usr/local/opt/openssl/bin:$PATH"
    export LDFLAGS="-L/usr/local/opt/openssl/lib"
    export CPPFLAGS="-I/usr/local/opt/openssl/include"
else
    echo "Unsupported OS type: $OS_TYPE"
    exit 1
fi

# Check if Solana CLI is installed
if command -v solana &> /dev/null; then
    echo "Solana CLI is already installed. Skipping installation."
else
    echo "Installing Solana CLI..."
    sh -c "$(curl -sSfL https://release.solana.com/v1.18.20/install)"
    # Ensure Solana is in the PATH
    if [ "$OS_TYPE" == "Linux" ]; then
        PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
        echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.profile
        echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin/$PATH"' >> ~/.bashrc
        source ~/.profile
    elif [ "$OS_TYPE" == "Mac" ]; then
        PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
        echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin/$PATH"' >> ~/.profile
        echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin/$PATH"' >> ~/.zshrc
        source ~/.profile
    fi
fi

# Verify Solana CLI installation
if ! command -v solana &> /dev/null; then
    echo "Solana CLI installation failed or not found in PATH."
    exit 1
fi

# Create Solana keypair
if [ -f "$HOME/.config/solana/id.json" ]; then
    echo "Existing wallet found. Skipping key generation."
else
    solana-keygen new
fi

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
        REPO_URL="https://github.com/nodecattel/ore-cli-jito.git"
        ORE_CLI_DIR="$HOME/oreminer/ore-cli-jito"
        ;;
    [Pp]*)
        echo "Switching to 'panda-opti-cores'..."
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
read -p "Do you wish to continue with setting up ore.sh? [Y/n] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "Proceeding with ore.sh setup..."
    cd $(dirname "$ORE_SH_PATH") # Change directory to where ore.sh is located
    ./ore.sh mine
else
    echo -e "Setup aborted. Run ore.sh manually to complete setup."
fi
