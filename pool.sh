#!/bin/bash
source ~/.profile

echo -e "\033[0;32m"
cat << "EOF"
█▀█ █▀█ █▀▀ █▀▄▀█ █ █▄░█ █▀▀ █▀█
█▄█ █▀▄ ██▄ █░▀░█ █ █░▀█ ██▄ █▀▄ ORE V2 - 2.3.0 mainnet
EOF
echo -e "Version 0.1.0 - NodeCattel OREHQ Pool Client"
echo -e "Made by NodeCattel & All the credits to HardhatChad\033[0m"

# Exit script if any command fails
set -e

# Check if ore-hq-client directory exists
if [ -d "ore-hq-client" ]; then
    echo -e "\033[0;32m\nDirectory 'ore-hq-client' exists. Checking for updates...\033[0m"
    cd ore-hq-client
    git pull
    cd ..
else
    echo -e "\033[0;32m\nCloning ore-hq-client repository...\033[0m"
    git clone https://github.com/nodecattel/ore-hq-client.git
fi

echo -e "\033[0;32m\nBuilding ore-hq-client...\033[0m"
cd ore-hq-client
cargo build --release

# Copy the binary to Cargo bin directory
echo -e "\033[0;32m\nCopying the binary to Cargo bin directory...\033[0m"
cp target/release/ore-hq-client ~/.cargo/bin/

# Fetching Solana address
default_keypair="$HOME/.config/solana/id.json"
conf_keypair="$(grep 'keypair' "$HOME/.ore/ore.conf" | cut -d'=' -f2 | xargs)"
if [ -z "$conf_keypair" ]; then
    conf_keypair="$default_keypair"
fi
solana_address=$(solana address --keypair "$conf_keypair")

echo -e "\033[0m\nYour Solana address: \033[0;32m$solana_address\033[0m"

# Prompt for whitelist
echo -e "\033[0m\nGet your address into the whitelist by sending a message to nodecattel on X (https://x.com/nodecattel)\033[0;32m"
read -p "Have you got into the whitelist for this address? [y/N]: " whitelist

if [[ "$whitelist" =~ ^[Yy]$ ]]; then
    text="OREHQ.NODECATTEL.XYZ is 0% signup fees, and we will take care of the RPC and transaction fees. let's hash ⛏️⛏️⛏️"
    length=${#text}
    echo -e "\033[1;35m\n"
    printf '%*s\n' "$length" '' | tr ' ' '='
    echo -e "\033[1m\033[0m$text\033[0m\033[1;35m"
    printf '%*s\n' "$length" '' | tr ' ' '='
    echo -e "\033[0m"
else
    echo -e "\033[0;31m\nPlease get your address into the whitelist first.\033[0m"
    exit 1
fi

# Determine the keypair path
echo -e "\033[0m\nDefault keypair is $conf_keypair.\033[0;32m"
read -p "Enter the path to the keypair (or press Enter to use the default): " keypair_path

if [ -z "$keypair_path" ]; then
    keypair_path="$conf_keypair"
fi

if [ ! -f "$keypair_path" ]; then
    echo -e "\033[0;31m\nError: Keypair file not found!\033[0m"
    exit 1
fi

echo -e "\033[0m\nSigning up to the pool...\033[0;32m"
ore-hq-client --keypair "$keypair_path" --url "orehq.nodecattel.xyz" signup

echo -e "\033[0m\nChecking ORE balance...\033[0;32m"
ore balance

# Get the number of cores
cores_available=$(nproc)
echo -e "\033[0m\nYour machine has $cores_available cores available.\033[0;32m"
read -p "Are you ready to join the pool? [y/N]: " ready

if [[ "$ready" =~ ^[Yy]$ ]]; then
    read -p "Enter the number of cores you want to use (Max: $cores_available): " cores
    if [ "$cores" -gt "$cores_available" ]; then
        echo -e "\033[0;31m\nError: You cannot use more than $cores_available cores.\033[0m"
        exit 1
    fi

    echo -e "\033[0;35m"
    cat << "EOF"
    |\__/,|   (`\
  _.|o o  |_   ) )
-(((---(((--------
EOF
    echo -e "\033[0m"
    echo -e "\033[0;32m\nFinal command to run:\033[0m ore-hq-client --keypair \"$keypair_path\" --url \"orehq.nodecattel.xyz\" mine --cores \"$cores\""
    echo -e "\033[0;31m\nOREHQ client initiated. You can stop the process anytime by pressing CTRL + C.\033[0m"
    ore-hq-client --keypair "$keypair_path" --url "orehq.nodecattel.xyz" mine --cores "$cores"
else
    echo -e "\033[0;31m\nExiting. Please run the script again when you are ready.\033[0m"
    exit 1
fi
