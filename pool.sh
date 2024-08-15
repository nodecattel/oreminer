#!/bin/bash
source ~/.profile

echo -e "\033[0;32m"
cat << "EOF"
█▀█ █▀█ █▀▀ █▀▄▀█ █ █▄░█ █▀▀ █▀█
█▄█ █▀▄ ██▄ █░▀░█ █ █░▀█ ██▄ █▀▄ ORE V2 - 2.3.0 mainnet
EOF
echo -e "Version 0.1.3 - NodeCattel Alvarium Pool Client"
echo -e "Made by NodeCattel & All the credits to HardhatChad\033[0m"

# Exit script if any command fails
set -e

# Display explanation of how the pool works
echo -e "\033[1;35m"
length=80  # Adjusted length for the full line to match the explanation width
printf '=%.0s' $(seq 1 $length)
echo -e "\033[0m"
echo -e "\033[0m"
echo -e "Joining a pool means computing the best hash per minute and submitting it"
echo -e "to the mining pool server. The server then submits combined hash received"
echo -e "from all miners to the chain in a single transaction. 5% will be the pool fee"
echo -e "and your reward will be given directly to you."
echo -e "\033[1;35m"
printf '=%.0s' $(seq 1 $length)
echo -e "\033[0m"

# Ensure the necessary packages are installed
echo -e "\033[0;32m\nChecking for required packages...\033[0m"
sudo apt-get install -y openssl pkg-config libssl-dev

# Check and remove existing ore-hq-client directory if exists
if [ -d "ore-hq-client" ]; then
    echo -e "\033[0;32m\nDirectory 'ore-hq-client' exists. Removing directory...\033[0m"
    rm -rf ore-hq-client
fi

# Install ore-pool-miner (alvarium-cli)
echo -e "\033[0;32m\nInstalling ore-pool-miner...\033[0m"
if [ -d "ore-pool-miner" ]; then
    echo -e "\033[0;32m\nDirectory 'ore-pool-miner' exists. Checking for updates...\033[0m"
    cd ore-pool-miner
    git pull
else
    git clone https://github.com/Bifrost-Technologies/ore-pool-miner.git
    cd ore-pool-miner
fi

# Build the ore-pool-miner project
cargo build --release

# Copy the binary to Cargo bin directory
echo -e "\033[0;32m\nCopying the binary to Cargo bin directory...\033[0m"
cp target/release/alvarium ~/.cargo/bin/

# Load values from ore.conf
config_file="$HOME/.ore/ore.conf"
RPC_URL=$(grep 'RPC' "$config_file" | cut -d'=' -f2 | xargs)
CORES=$(grep 'CORES' "$config_file" | cut -d'=' -f2 | xargs)
KEYPAIR_PATH=$(grep 'KEYPAIR_PATH' "$config_file" | cut -d'=' -f2 | xargs)

# Fetch the default wallet address using the solana address command
WALLET_ADDRESS=$(solana address --keypair "$KEYPAIR_PATH")

# Prompt user to adjust or confirm values
echo -e "\033[0m\nRPC URL (default: $RPC_URL):\033[0;32m"
read -p "Enter new RPC URL or press Enter to keep the default: " input_rpc
if [[ -n "$input_rpc" ]]; then
    RPC_URL="$input_rpc"
fi

echo -e "\033[0m\nWallet Address (default: $WALLET_ADDRESS):\033[0;32m"
read -p "Enter new Wallet Address or press Enter to keep the default: " input_wallet
if [[ -n "$input_wallet" ]]; then
    WALLET_ADDRESS="$input_wallet"
fi

echo -e "\033[0m\nNumber of Cores (default: $CORES, Max: $(nproc)):\033[0;32m"
read -p "Enter number of cores or press Enter to keep the default: " input_cores
if [[ -n "$input_cores" ]]; then
    CORES="$input_cores"
fi

BUFFER_TIME=8  # Alvarium Pool Mine recommended value
echo -e "\033[0m\nBuffer Time (default: $BUFFER_TIME):\033[0;32m"
read -p "Enter buffer time or press Enter to keep the default: " input_buffer
if [[ -n "$input_buffer" ]]; then
    BUFFER_TIME="$input_buffer"
fi

echo -e "\033[0;35m"
cat << "EOF"
    |\__/,|   (`\
  _.|o o  |_   ) )
-(((---(((--------
EOF
echo -e "\033[0m"

# Final command execution
echo -e "\033[0;32m\nFinal command to run:\033[0m alvarium $RPC_URL $WALLET_ADDRESS $CORES $BUFFER_TIME"
echo -e "\033[0;31m\nAlvarium client initiated. You can stop the process anytime by pressing CTRL + C.\033[0m"
alvarium $RPC_URL $WALLET_ADDRESS $CORES $BUFFER_TIME
