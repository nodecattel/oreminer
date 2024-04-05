#!/bin/bash

# Version Information and Credits
echo -e "\033[0;32m"
cat << "EOF"
█▀█ █▀█ █▀▀ █▀▄▀█ █ █▄░█ █▀▀ █▀█
█▄█ █▀▄ ██▄ █░▀░█ █ █░▀█ ██▄ █▀▄
EOF
echo -e "Version 0.1.2 - Ore Miner"
echo -e "Made by NodeCattel & All the credits to HardhatChad\033[0m\n"

# Initial variable settings
ORE_DIR="$HOME/.ore"
CONFIG_FILE="$ORE_DIR/ore.conf"
DEFAULT_RPC="https://api.mainnet-beta.solana.com"
BASE_PRIORITY_FEE="200000"  # This is the base priority fee before any presets
DEFAULT_THREADS="4"
KEYPAIR_PATH="$HOME/.config/solana/id.json"

# Create ORE directory
mkdir -p "$ORE_DIR"

# Configuration setup replacing whiptail with read
echo "Enter your RPC URL (Default: $DEFAULT_RPC): "
read -r input_rpc
RPC="${input_rpc:-$DEFAULT_RPC}"

echo "Enter your base priority fee (Default: $BASE_PRIORITY_FEE): "
read -r input_fee
PRIORITY_FEE="${input_fee:-$BASE_PRIORITY_FEE}"

echo "Enter number of threads (Default: $DEFAULT_THREADS): "
read -r input_threads
THREADS="${input_threads:-$DEFAULT_THREADS}"

# Confirm and update config file
echo "RPC=${RPC}" > "$CONFIG_FILE"
echo "PRIORITY_FEE=${PRIORITY_FEE}" >> "$CONFIG_FILE"
echo "THREADS=${THREADS}" >> "$CONFIG_FILE"
echo "KEYPAIR_PATH=${KEYPAIR_PATH}" >> "$CONFIG_FILE"

# Generate Solana keypair if it does not exist
if [ ! -f "$KEYPAIR_PATH" ]; then
    echo -e "\033[0;32mGenerating a new Solana keypair...\033[0m"
    echo -e "\033[1;33mIMPORTANT: The next output will include your seed phrase. Please make sure to write it down and store it safely!\033[0m"
    read -p "Press enter to continue and see your seed phrase..."
    solana-keygen new --outfile "$KEYPAIR_PATH"
    echo -e "\033[1;33mPlease make sure you have saved your seed phrase securely.\033[0m"
    read -p "Backup done? Press enter to continue..."
fi

# Extract the public key (wallet address) from the keypair
WALLET_ADDRESS=$(solana-keygen pubkey "$KEYPAIR_PATH")
echo "WALLET_ADDRESS=${WALLET_ADDRESS}" >> "$CONFIG_FILE"

# Load the updated configuration
source "$CONFIG_FILE"

# Simple preset selection menu replaced with read
echo "Choose your mining speed preset:"
echo "1) Normal - Use default priority-fee setting"
echo "2) Fast - +25% increase to the priority-fee"
echo "3) Chad - +50% increase to the priority-fee"
read -p "Enter choice [1-3]: " preset_choice

case $preset_choice in
    1)
        CHOICE="Normal"
        ADJUSTED_PRIORITY_FEE=$PRIORITY_FEE
        ;;
    2)
        CHOICE="Fast"
        ADJUSTED_PRIORITY_FEE=$((PRIORITY_FEE + PRIORITY_FEE * 25 / 100))
        ;;
    3)
        CHOICE="Chad"
        ADJUSTED_PRIORITY_FEE=$((PRIORITY_FEE + PRIORITY_FEE * 50 / 100))
        ;;
    *)
        echo "Invalid selection, exiting."
        exit 1
        ;;
esac

# Update config with the latest settings and wallet address
echo "ADJUSTED_PRIORITY_FEE=${ADJUSTED_PRIORITY_FEE}" >> "$CONFIG_FILE"
source "$CONFIG_FILE"

# Confirm to start mining with the wallet address on a new line
echo -e "Selected preset: \033[1;32m${CHOICE}\033[0m"
echo -e "Adjusted Priority Fee: \033[1;32m${ADJUSTED_PRIORITY_FEE}\033[0m"
echo -e "You are mining to the wallet address: \033[1;32m${WALLET_ADDRESS}\033[0m"
read -p "Press any key to start mining or CTRL+C to cancel..."

# Display configuration
echo -e "\033[0;32mStarting mining operation with the following configuration:\033[0m"
echo "RPC URL: $RPC"
echo "Keypair Path: $KEYPAIR_PATH"
echo "Priority Fee: $ADJUSTED_PRIORITY_FEE"
echo "Threads: $THREADS"
echo "Wallet Address: $WALLET_ADDRESS"

# Start the mining operation
while :; do
    echo "Mining operation started. Press CTRL+C to stop."
    # Execute the actual command to start mining, replace with the correct command as needed.
    ore --rpc "$RPC" --keypair "$KEYPAIR_PATH" --priority-fee "$ADJUSTED_PRIORITY_FEE" mine --threads "$THREADS"
    echo -e "\033[0;32mMining process exited, restarting in 3 seconds...\033[0m"
    sleep 3
done

