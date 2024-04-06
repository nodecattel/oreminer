#!/bin/bash

# Configuration directory and file
ORE_DIR="$HOME/.ore"
CONFIG_FILE="$ORE_DIR/ore.conf"
WALLETS_FILE="$ORE_DIR/wallets.json"

# Default values
DEFAULT_SOL_AMOUNT="0.01"  # 0.01 SOL
DEFAULT_KEYPAIR_PATH="$HOME/.config/solana/id.json"

# Ensure the ORE directory exists
mkdir -p "$ORE_DIR"

# Load existing configuration if available
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "No existing configuration found. Using default values."
fi

# Function to prompt the user and get confirmation
confirm_prompt() {
    read -rp "$1 [y/n]: " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            true
            ;;
        *)
            false
            ;;
    esac
}

# Configuration setup with user input, pre-filling with current or default values
echo -e "\033[0;32mEnter the number of wallets to create:\033[0m "
read -r num_wallets

echo -e "\033[0;32mEnter the amount of SOL to send to each wallet (default: ${DEFAULT_SOL_AMOUNT}):\033[0m "
read -r sol_amount
sol_amount="${sol_amount:-$DEFAULT_SOL_AMOUNT}"

# Prompt user to confirm if they want to force replacement of existing wallet files
confirm_prompt "Do you want to force replacement of existing wallet files?"

# Generate wallets starting from id2.json and save each wallet's information in a separate JSON file
for ((i=2; i<=num_wallets+1; i++))
do
    # Check if the file already exists and prompt user if they want to replace it
    if [[ -f "$HOME/.config/solana/id$i.json" ]]; then
        if confirm_prompt "Wallet file id$i.json already exists. Do you want to replace it?"; then
            solana-keygen new --outfile "$HOME/.config/solana/id$i.json" --force
        else
            echo "Skipping wallet file id$i.json."
        fi
    else
        solana-keygen new --outfile "$HOME/.config/solana/id$i.json"
    fi
done

# Create an array to store recipient information
recipients=()

# Loop to generate recipient information
for ((i=2; i<=num_wallets+1; i++))
do
    # Extract the public key (address) from the keypair
    address=$(solana-keygen pubkey "$HOME/.config/solana/id$i.json")
    
    # Append recipient information to the array
    recipients+=("{\"address\": \"$address\", \"amount\": $sol_amount}")
done

# Convert the array to JSON format
json_array="["
for ((i=0; i<num_wallets; i++))
do
    json_array+="${recipients[$i]}"
    if [[ $i -lt $((num_wallets-1)) ]]; then
        json_array+=","
    fi
done
json_array+="]"

# Output the JSON array to a file
echo "$json_array" > "$WALLETS_FILE"

echo "Wallets created successfully and recipient information exported to $WALLETS_FILE."
