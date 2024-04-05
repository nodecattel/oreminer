#!/bin/bash
# Version Information, and Credits
echo -e "\033[0;32m" # Start green color
cat << "EOF"
█▀█ █▀█ █▀▀ █▀▄▀█ █ █▄░█ █▀▀ █▀█
█▄█ █▀▄ ██▄ █░▀░█ █ █░▀█ ██▄ █▀▄
EOF
echo -e "Version 0.1.0 - Ore Miner"
echo -e "Made by NodeCattel\033[0m" # End green color

# Initial variable settings
ORE_DIR="$HOME/.ore"
CONFIG_FILE="$ORE_DIR/ore.conf"
DEFAULT_RPC="https://api.mainnet-beta.solana.com"
BASE_PRIORITY_FEE="400000" # This is the base priority fee before any presets
DEFAULT_THREADS="6"
KEYPAIR_PATH="$HOME/.config/solana/id.json"

# Create ORE directory
mkdir -p "$ORE_DIR"

# Display help message
show_help() {
    echo -e "\033[0;32mUsage: $0 [options]\033[0m"
    echo "Options:"
    echo "  -r <RPC URL>        Specify the RPC URL."
    echo "  -f <priority fee>   Specify the priority fee."
    echo "  -t <threads>        Specify the number of threads."
    echo "  --help              Display this help message and exit."
}

# Generate Solana keypair if it does not exist
if [ ! -f "$KEYPAIR_PATH" ]; then
    echo -e "\033[0;32mGenerating a new Solana keypair...\033[0m"
    echo -e "\033[1;33mIMPORTANT: The next output will include your seed phrase. Please make sure to write it down and store it safely!\033[0m"
    read -p "Press enter to continue and see your seed phrase..."
    solana-keygen new --outfile "$KEYPAIR_PATH"
    echo -e "\033[1;33mPlease make sure you have saved your seed phrase securely.\033[0m"
    read -p "Backup done?, press enter to continue..."
fi

# Extract the public key (wallet address) from the keypair
WALLET_ADDRESS=$(solana-keygen pubkey "$KEYPAIR_PATH")

# Preset selection using whiptail
CHOICE=$(whiptail --title "Mining Preset Selection" --menu "Choose your mining speed preset:" 15 60 4 \
"Normal"  "Use default priority-fee" \
"Fast"    "+25% increase priority-fee" \
"Chad"    "+50% increase priority-fee" 3>&1 1>&2 2>&3)

case $CHOICE in
    "Normal")
        ADJUSTED_PRIORITY_FEE=$BASE_PRIORITY_FEE
        ;;
    "Fast")
        ADJUSTED_PRIORITY_FEE=$((BASE_PRIORITY_FEE + BASE_PRIORITY_FEE * 25 / 100))
        ;;
    "Chad")
        ADJUSTED_PRIORITY_FEE=$((BASE_PRIORITY_FEE + BASE_PRIORITY_FEE * 50 / 100))
        ;;
    *)
        # Handle case where user exits whiptail dialog without making a selection
        echo "No valid selection made, exiting."
        exit 1
        ;;
esac

# Update config with latest settings and wallet address
echo "RPC=${RPC:-$DEFAULT_RPC}" > "$CONFIG_FILE"
echo "PRIORITY_FEE=$ADJUSTED_PRIORITY_FEE" >> "$CONFIG_FILE"
echo "THREADS=${THREADS:-$DEFAULT_THREADS}" >> "$CONFIG_FILE"
echo "WALLET_ADDRESS=$WALLET_ADDRESS" >> "$CONFIG_FILE"
echo "KEYPAIR_PATH=$KEYPAIR_PATH" >> "$CONFIG_FILE"

# Load the updated configuration
source "$CONFIG_FILE"

# Confirm to start mining with the wallet address on a new line
echo -e "Selected preset: \033[1;32m$CHOICE\033[0m"
echo -e "Adjusted Priority Fee: \033[1;32m$ADJUSTED_PRIORITY_FEE\033[0m"
echo -e "You are mining to the wallet address: \033[1;32m$WALLET_ADDRESS\033[0m"
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
    ore \
        --rpc "$RPC" \
        --keypair "$KEYPAIR_PATH" \
        --priority-fee "$ADJUSTED_PRIORITY_FEE" \
        mine \
        --threads "$THREADS"
    echo -e "\033[0;32mMining process exited, restarting in 3 seconds...\033[0m"
    sleep 3
done
