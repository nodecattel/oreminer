#!/bin/bash
source ~/.profile

echo -e "\033[0;32m"
cat << "EOF"
█▀█ █▀█ █▀▀ █▀▄▀█ █ █▄░█ █▀▀ █▀█
█▄█ █▀▄ ██▄ █░▀░█ █ █░▀█ ██▄ █▀▄ V2
EOF
echo -e "Version 0.1.0 - Ore Cli Claim"
echo -e "Made by NodeCattel & All the credits to HardhatChad\033[0m"

# Load existing configuration
ORE_DIR="$HOME/.ore"
CONFIG_FILE="$ORE_DIR/ore.conf"

if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo -e "\033[0;31mConfiguration file not found. Please run the ore.sh setup script first.\033[0m"
    exit 1
fi

# Prompt for amount to claim
echo -e "\033[0;32mEnter the amount of ORE to claim (leave empty to claim the maximum amount):\033[0m"
read -r input_amount

# Prompt for beneficiary wallet address
echo -e "\033[0;32mDo you want to send the rewards to a specific wallet address? [Y/n]\033[0m"
read -r beneficiary_answer
if [[ "$beneficiary_answer" =~ ^[Yy]$ ]]; then
    echo -e "\033[0;32mEnter the beneficiary wallet address:\033[0m"
    read -r beneficiary_address
    beneficiary_flag="--beneficiary $beneficiary_address"
else
    beneficiary_flag=""
fi

# Construct the claim command
claim_command="ore claim --rpc $RPC --keypair $KEYPAIR_PATH --priority-fee $ADJUSTED_PRIORITY_FEE $beneficiary_flag"

# Add amount flag if specified
if [[ -n "$input_amount" ]]; then
    claim_command="$claim_command --amount $input_amount"
fi

# Execute the claim command
echo -e "\033[0;32mExecuting the claim command:\033[0m"
echo -e $claim_command
$claim_command

# Check the result of the command execution
if [[ $? -eq 0 ]]; then
    echo -e "\033[0;32mClaim command executed successfully.\033[0m"
else
    echo -e "\033[0;31mError executing the claim command.\033[0m"
fi
