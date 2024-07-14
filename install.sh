#!/bin/bash
source ~/.profile

echo -e "\033[0;32m"
cat << "EOF"
█▀█ █▀█ █▀▀ █▀▄▀█ █ █▄░█ █▀▀ █▀█
█▄█ █▀▄ ██▄ █░▀░█ █ █░▀█ ██▄ █▀▄ V2 - 1.0.0-alpha
EOF
echo -e "Version 0.2.1 - Ore Cli installer + PMC ui"
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
    # Install build tools (Ubuntu/Debian specific)
    echo "Installing build tools..."
    sudo apt update
    sudo apt install -y build-essential

elif [ "$OS_TYPE" == "Mac" ]; then
    echo "Installing build tools for Mac..."
    xcode-select --install || echo "Xcode command line tools already installed."

else
    echo "Unsupported OS type: $OS_TYPE"
    exit 1
fi

# Check if Solana CLI is installed
if command -v solana &> /dev/null; then
    echo "Solana CLI is already installed. Skipping installation."
else
    echo "Installing Solana CLI..."
    sh -c "$(curl -sSfL https://release.solana.com/v1.18.4/install)"
    # Ensure Solana is in the PATH
    if [ "$OS_TYPE" == "Linux" ]; then
        export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
        echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.bashrc
        source ~/.bashrc
    elif [ "$OS_TYPE" == "Mac" ]; then
        export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
        echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.zshrc
        source ~/.zshrc
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

# Prompt to select environment (mainnet or devnet)
read -p "Choose Solana network (m for mainnet, d for devnet): " env_choice
case "$env_choice" in
    [Mm]*)
        echo "Switching to 'mainnet'..."
        solana config set --url https://api.mainnet-beta.solana.com
        ;;
    [Dd]*)
        echo "Switching to 'devnet'..."
        solana config set --url https://api.devnet.solana.com
        ;;
    *)
        echo "Invalid choice. Staying on current environment."
        ;;
esac

# Clone or update ORE-CLI from source
ORE_CLI_DIR="$HOME/ore-cli"
if [ -d "$ORE_CLI_DIR" ]; then
    echo "Updating ORE-CLI repository..."
    cd $ORE_CLI_DIR
    git pull origin master || git pull origin main
else
    echo "Cloning ORE-CLI repository..."
    git clone https://github.com/regolith-labs/ore-cli $ORE_CLI_DIR
    cd $ORE_CLI_DIR
fi

# Build the ORE-CLI binary
echo "Building ORE-CLI..."
cargo build --release
# Move the binary to the appropriate location
cp target/release/ore $HOME/.cargo/bin/ore
cd ..
echo "Ore CLI has been installed from source and updated to the latest version."

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
    cd $(dirname "$ORE_SH_PATH") # Change directory to where ore.sh is located
    ./ore.sh mine
else
    echo -e "Setup aborted. Run ore.sh manually to complete setup.\033[0;35m by NodeCattel\033[0m"
fi
