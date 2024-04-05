#!/bin/bash

# Version Information and Credits
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
BASE_PRIORITY_FEE="200000" # This is the base priority fee before any presets
DEFAULT_THREADS="4"
KEYPAIR_PATH="$HOME/.config/solana/id.json"

# Create ORE directory
mkdir -p "$ORE_DIR"

# Configuration setup using whiptail
RPC=$(whiptail --inputbox "Enter your RPC URL" 8 78 $DEFAULT_RPC --title "RPC Configuration" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus != 0 ]; then
    echo "No RPC URL entered, exiting."
    exit 1
fi

PRIORITY_FEE=$(whiptail --inputbox "Enter your base priority fee" 8 78 $BASE_PRIORITY_FEE --title "Priority Fee Configuration" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus != 0 ]; then
    echo "No priority fee entered, using default."
    PRIORITY_FEE=$BASE_PRIORITY_FEE
fi

THREADS=$(whiptail --inputbox "Enter number of threads" 8 78 $DEFAULT_THREADS --title "Thread Configuration" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus != 0 ]; then
    echo "No thread count entered, using default."
    THREADS=$DEFAULT_THREADS
fi

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

# Preset selection menu
CHOICE=$(whiptail --title "Mining Preset Selection" --menu "Choose your mining speed preset:" 15 60 4 \
"Normal"  "Use default priority-fee setting" \
"Fast"    "+25% increase to the priority-fee" \
"Chad"    "+50% increase to the priority-fee" 3>&1 1>&2 2>&3)

case $CHOICE in
    "Normal")
        ADJUSTED_PRIORITY_FEE=$PRIORITY_FEE
        ;;
    "Fast")
        ADJUSTED_PRIORITY_FEE=$((PRIORITY_FEE + PRIORITY_FEE * 25 / 100))
        ;;
    "Chad")
        ADJUSTED_PRIORITY_FEE=$((PRIORITY_FEE + PRIORITY_FEE * 50 / 100))
        ;;
    *)
        # Handle case where user exits whiptail dialog without making a selection
        echo "No valid selection made, exiting."
        exit 1
        ;;
esac

# Update config with the latest settings and wallet address
echo "RPC=$RPC" > "$CONFIG_FILE"
echo "PRIORITY_FEE=$ADJUSTED_PRIORITY_FEE" >> "$CONFIG_FILE"
echo "THREADS=$THREADS" >> "$CONFIG_FILE"
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
    # Replace the following line with the actual command to start mining.
    # The example command below is a placeholder and should be replaced.
    ore \
        --rpc "$RPC" \
        --keypair "$KEYPAIR_PATH" \
        --priority-fee "$ADJUSTED_PRIORITY_FEE" \
        mine \
        --threads "$THREADS"
    echo -e "\033[0;32mMining process exited, restarting in 3 seconds...\033[0m"
    sleep 3
done
