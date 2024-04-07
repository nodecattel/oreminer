#!/bin/bash
source ~/.profile

# Version Information and Credits
echo -e "\033[0;32m"
cat << "EOF"
█▀█ █▀█ █▀▀ █▀▄▀█ █ █▄░█ █▀▀ █▀█
█▄█ █▀▄ ██▄ █░▀░█ █ █░▀█ ██▄ █▀▄
EOF
echo -e "Version 0.1.0 - Ore Claim Repeater"
echo -e "Made by NodeCattel & All the credits to HardhatChad\033[0m\n"

# Configuration file path and color codes
ORE_CONF="$HOME/.ore/ore.conf"
GREEN="\033[0;32m"
WHITE="\033[0;37m"
BLUE="\033[0;34m"
RED="\033[0;31m"
NC="\033[0m" # No Color

# Load configurations from ore.conf
if [ -f "$ORE_CONF" ]; then
    source "$ORE_CONF"
    echo -e "${GREEN}Current configuration loaded from ore.conf:${NC}"
else
    echo -e "${RED}ore.conf not found. Please ensure $ORE_CONF exists.${NC}"
    exit 1
fi

# Prompt user for RPC URL and priority fee with defaults
echo -e "${GREEN}Enter your RPC URL (Default: ${RPC}):${NC}"
read -r input_rpc
RPC="${input_rpc:-$RPC}"

echo -e "${GREEN}Enter your priority fee (Default: ${ADJUSTED_PRIORITY_FEE}):${NC}"
read -r input_fee
FEE="${input_fee:-${ADJUSTED_PRIORITY_FEE}}"

# Temporary file to capture command output
TMP_OUTPUT="/tmp/ore_claim_output.txt"

# Loop to automatically retry on "Max retries"
while true; do
    echo -e "${GREEN}Attempting to claim with the following settings:${NC}"
    echo -e "${GREEN}RPC URL: $RPC${NC}"
    echo -e "${GREEN}Keypair Path: $KEYPAIR_PATH${NC}"
    echo -e "${GREEN}Priority Fee: $FEE${NC}"

    # Construct and display the command
    COMMAND="ore --rpc \"$RPC\" --keypair \"$KEYPAIR_PATH\" --priority-fee \"$FEE\" claim"
    echo -e "${BLUE}Executing command: $COMMAND${NC}"

    # Execute command and capture output to a file, displaying it in real-time
    eval $COMMAND | tee $TMP_OUTPUT
    EXIT_STATUS=${PIPESTATUS[0]}

    # Analyze output for "Max retries" error
    if grep -q "Max retries" $TMP_OUTPUT; then
        echo -e "${RED}Encountered 'Max retries' error, retrying in 2 seconds...${NC}"
        sleep 2
    elif [ $EXIT_STATUS -ne 0 ]; then
        echo -e "${RED}Encountered an error, stopping.${NC}"
        break
    else
        echo -e "${GREEN}Claim successful.${NC}"
        break
    fi
done
