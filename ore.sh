#!/bin/bash

# Detect OS and source appropriate profile file
OS="$(uname)"
if [[ "$OS" == "Darwin" ]]; then
    source ~/.profile
else
    source ~/.bashrc
fi

# Version Information and Credits
echo -e "\033[0;32m"
cat << "EOF"
█▀█ █▀█ █▀▀ █▀▄▀█ █ █▄░█ █▀▀ █▀█
█▄█ █▀▄ ██▄ █░▀░█ █ █░▀█ ██▄ █▀▄ V2
EOF
echo -e "Version 0.2.3 - Ore Miner"
echo -e "Made by NodeCattel & All the credits to HardhatChad\033[0m\n"

# Configuration directory and file
ORE_DIR="$HOME/.ore"
CONFIG_FILE="$ORE_DIR/ore.conf"

# Default values
DEFAULT_RPC="https://api.mainnet-beta.solana.com"
BASE_PRIORITY_FEE="0"  # This is the base priority fee before any presets
DEFAULT_THREADS="1"
DEFAULT_KEYPAIR_PATH="$HOME/.config/solana/id.json"
DEFAULT_BUFFER_TIME="5"
DEFAULT_DYNAMIC_FEE_MAX="500000"

# Ensure the ORE directory exists
mkdir -p "$ORE_DIR"

# Load existing configuration if available
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "No existing configuration found. Using default values."
fi

# Set appropriate commands based on the OS
if [[ "$OS" == "Darwin" ]]; then
    ECHO="echo"
    SLEEP="sleep"
else
    ECHO="echo -e"
    SLEEP="sleep"
fi

# Command line arguments handling
COMMAND=$1
shift

show_help() {
    $ECHO "A command line interface for the ORE cryptocurrency mining."
    $ECHO ""
    $ECHO "Usage: ./ore.sh <COMMAND>"
    $ECHO ""
    $ECHO -e "To run: \033[0;32m ./ore.sh mine\033[0m"
    $ECHO ""
    $ECHO "Commands:"
    $ECHO "  balance    Fetch the Ore balance of an account"
    $ECHO "  benchmark  Benchmark your machine's hashrate"
    $ECHO "  busses     Fetch the bus account balances"
    $ECHO "  claim      Claim available mining rewards use --amount <ORE AMOUNT> to partial claim"
    $ECHO "  close      Close your onchain accounts to recover rent"
    $ECHO "  config     Fetch the program config"
    $ECHO "  mine       Start mining Ore"
    $ECHO "  rewards    Fetch the reward rate for each difficulty level"
    $ECHO "  stake      Stake ore to earn a multiplier on your mining rewards use --amount <ORE AMOUNT> to partial stake"
    $ECHO "  upgrade    Upgrade your ORE tokens from v1 to v2"
}

# Function to fetch the balance of an account
fetch_balance() {
    $ECHO "Fetching balance for wallet address: ${WALLET_ADDRESS}"
    ore balance --rpc "$RPC" --keypair "$KEYPAIR_PATH"
}

# Function to benchmark the machine's hashrate
benchmark() {
    $ECHO "Benchmarking hashrate..."
    ore benchmark
}

# Function to fetch the bus account balances
fetch_busses() {
    $ECHO "Fetching bus account balances..."
    ore busses --rpc "$RPC" --keypair "$KEYPAIR_PATH"
}

# Function to claim available mining rewards
claim_rewards() {
    local AMOUNT=""
    local RECEIVER=""
    local PRIORITY_FEE=""

    while [[ "$1" != "" ]]; do
        case $1 in
            --amount)
                shift
                AMOUNT="--amount $1"
                ;;
            --to)
                shift
                RECEIVER="--to $1"
                ;;
            *)
                ;;
        esac
        shift
    done

    $ECHO "Enter desired priority fee in microlamports (default is 0): "
    read -r input_fee
    PRIORITY_FEE="${input_fee:-0}"

    $ECHO "Claiming available mining rewards..."
    ore claim --rpc "$RPC" --keypair "$KEYPAIR_PATH" --priority-fee "$PRIORITY_FEE" $AMOUNT $RECEIVER
}

# Function to fetch the reward rate for each difficulty level
fetch_rewards() {
    $ECHO "Fetching reward rate for each difficulty level..."
    ore rewards
}

# Function to stake ore
stake_ore() {
    local AMOUNT=""
    local SENDER=""

    while [[ "$1" != "" ]]; do
        case $1 in
            --amount)
                shift
                AMOUNT="--amount $1"
                ;;
            --sender)
                shift
                SENDER="--sender $1"
                ;;
            *)
                ;;
        esac
        shift
    done

    $ECHO "Staking ore to earn a multiplier on your mining rewards..."
    ore stake --rpc "$RPC" --keypair "$KEYPAIR_PATH" --priority-fee "$PRIORITY_FEE" $AMOUNT $SENDER
}

# Function to close onchain accounts to recover rent
close_accounts() {
    $ECHO "Closing onchain accounts to recover rent..."
    ore close --rpc "$RPC" --keypair "$KEYPAIR_PATH"
}

# Function to fetch the program config
fetch_config() {
    $ECHO "Fetching the program config..."
    ore config --rpc "$RPC"
}

# Function to upgrade ORE tokens from v1 to v2
upgrade_tokens() {
    $ECHO "Upgrading your ORE tokens from v1 to v2..."
    ore upgrade --rpc "$RPC" --keypair "$KEYPAIR_PATH"
}

# Function to run mining operation in background
run_mining() {
    while :; do
        $ECHO "Mining operation started. Press CTRL+C to stop."
        if [[ -n "$DYNAMIC_FEE_URL" ]]; then
            ore mine --rpc "$RPC" --keypair "$KEYPAIR_PATH" --threads "$THREADS" --dynamic-fee-url "$DYNAMIC_FEE_URL" --dynamic-fee-max "$DYNAMIC_FEE_MAX"
        else
            ore mine --rpc "$RPC" --keypair "$KEYPAIR_PATH" --priority-fee "$ADJUSTED_PRIORITY_FEE" --threads "$THREADS" --buffer-time "$BUFFER_TIME"
        fi
        if [[ $? -ne 0 ]]; then
            $ECHO "\033[0;32mMining process exited with error, restarting in 3 seconds...\033[0m"
            $SLEEP 3
        else
            $ECHO "\033[0;32mMining process completed successfully.\033[0m"
            break
        fi
    done
}

# Handle commands
case "$COMMAND" in
    balance)
        fetch_balance
        ;;
    benchmark)
        benchmark
        ;;
    busses)
        fetch_busses
        ;;
    claim)
        $ECHO "Enter wallet address to receive ORE claim (or leave empty to use the default wallet): "
        read -r input_receiver
        if [[ -n "$input_receiver" ]]; then
            RECEIVER="--to $input_receiver"
        fi
        claim_rewards "$RECEIVER" "$@"
        ;;
    close)
        close_accounts
        ;;
    config)
        fetch_config
        ;;
    rewards)
        fetch_rewards
        ;;
    stake)
        stake_ore "$@"
        ;;
    upgrade)
        upgrade_tokens
        ;;
    mine)
        # Display Ore Cli version
        ore_version=$(ore --version)
        $ECHO "Cli Version: $ore_version"

        # Configuration setup with user input, pre-filling with current or default values
        $ECHO "Enter your RPC URL (Current: ${RPC:-$DEFAULT_RPC}): "
        read -r input_rpc
        RPC="${input_rpc:-${RPC:-$DEFAULT_RPC}}"

        $ECHO "Enter dynamic fee URL (fill n or N if not using dynamic fees) (Current: ${DYNAMIC_FEE_URL:-None}): "
        read -r input_dynamic_fee_url
        if [[ "$input_dynamic_fee_url" =~ ^[Nn]$ ]]; then
            DYNAMIC_FEE_URL=""
            $ECHO "Enter your base priority fee (Current: ${PRIORITY_FEE:-$BASE_PRIORITY_FEE}): "
            read -r input_fee
            PRIORITY_FEE="${input_fee:-${PRIORITY_FEE:-$BASE_PRIORITY_FEE}}"
        else
            DYNAMIC_FEE_URL="${input_dynamic_fee_url:-${DYNAMIC_FEE_URL}}"
            $ECHO "Enter maximum dynamic fee (Current: ${DYNAMIC_FEE_MAX:-$DEFAULT_DYNAMIC_FEE_MAX}): "
            read -r input_dynamic_fee_max
            DYNAMIC_FEE_MAX="${input_dynamic_fee_max:-${DYNAMIC_FEE_MAX:-$DEFAULT_DYNAMIC_FEE_MAX}}"
        fi

        $ECHO "Enter number of threads (Current: ${THREADS:-$DEFAULT_THREADS}): "
        read -r input_threads
        THREADS="${input_threads:-${THREADS:-$DEFAULT_THREADS}}"

        $ECHO "Enter your keypair path (Current: ${KEYPAIR_PATH:-$DEFAULT_KEYPAIR_PATH}): "
        read -r input_keypair
        KEYPAIR_PATH="${input_keypair:-${KEYPAIR_PATH:-$DEFAULT_KEYPAIR_PATH}}"

        $ECHO "Enter buffer time in seconds (Current: ${BUFFER_TIME:-$DEFAULT_BUFFER_TIME}): "
        read -r input_buffer_time
        BUFFER_TIME="${input_buffer_time:-${BUFFER_TIME:-$DEFAULT_BUFFER_TIME}}"

        # Confirm and update the config file
        $ECHO "Updating configuration..."
        {
            $ECHO "RPC=$RPC"
            $ECHO "PRIORITY_FEE=$PRIORITY_FEE"
            $ECHO "THREADS=$THREADS"
            $ECHO "KEYPAIR_PATH=$KEYPAIR_PATH"
            $ECHO "BUFFER_TIME=$BUFFER_TIME"
            $ECHO "DYNAMIC_FEE_URL=$DYNAMIC_FEE_URL"
            $ECHO "DYNAMIC_FEE_MAX=$DYNAMIC_FEE_MAX"
        } > "$CONFIG_FILE"

        # Generate Solana keypair if it does not exist
        if [ ! -f "$KEYPAIR_PATH" ]; then
            $ECHO "\033[0;32mGenerating a new Solana keypair...\033[0m"
            $ECHO "\033[1;33mIMPORTANT: The next output will include your seed phrase. Please make sure to write it down and store it safely!\033[0m"
            read -p "Press enter to continue and see your seed phrase..."
            solana-keygen new --outfile "$KEYPAIR_PATH"
            $ECHO "\033[1;33mPlease make sure you have saved your seed phrase securely.\033[0m"
            read -p "Backup done? Press enter to continue..."
        fi

        # Extract the public key (wallet address) from the keypair
        WALLET_ADDRESS=$(solana-keygen pubkey "$KEYPAIR_PATH")
        echo "WALLET_ADDRESS=${WALLET_ADDRESS}" >> "$CONFIG_FILE"

        # Load the updated configuration
        source "$CONFIG_FILE"

        # Skip preset selection if dynamic fee URL is provided
        if [[ -z "$DYNAMIC_FEE_URL" ]]; then
            # Preset selection menu
            $ECHO "Choose your mining speed preset:"
            $ECHO "1) Normal - Use default priority-fee setting"
            $ECHO "2) Fast - +25% increase to the priority-fee"
            $ECHO "3) Chad - +50% increase to the priority-fee"

            while true; do
                read -p "Enter choice [1-3]: " preset_choice
                if [[ "$preset_choice" =~ ^[1-3]$ ]]; then
                    break
                else
                    $ECHO "Invalid selection. Please enter a number between 1 and 3."
                fi
            done

            case $preset_choice in
                1)
                    CHOICE="Normal"
                    ADJUSTED_PRIORITY_FEE=$PRIORITY_FEE
                    ;;
                2)
                    CHOICE="Fast"
                    ADJUSTED_PRIORITY_FEE=$(printf "%.0f" $(echo "$PRIORITY_FEE + $PRIORITY_FEE * 0.25" | bc))
                    ;;
                3)
                    CHOICE="Chad"
                    ADJUSTED_PRIORITY_FEE=$(printf "%.0f" $(echo "$PRIORITY_FEE + $PRIORITY_FEE * 0.50" | bc))
                    ;;
            esac

            # Update config with the latest settings and wallet address
            {
                $ECHO "ADJUSTED_PRIORITY_FEE=${ADJUSTED_PRIORITY_FEE}"
            } >> "$CONFIG_FILE"

            # Confirm to start mining with the wallet address on a new line
            $ECHO -e "Selected preset: \033[1;32m${CHOICE}\033[0m"
            $ECHO -e "Adjusted Priority Fee: \033[1;32m${ADJUSTED_PRIORITY_FEE}\033[0m"
        fi

        $ECHO -e "You are mining to the wallet address: \033[1;32m${WALLET_ADDRESS}\033[0m"

        # Print the final command used
        if [[ -n "$DYNAMIC_FEE_URL" ]]; then
            final_command="ore mine --rpc \"$RPC\" --keypair \"$KEYPAIR_PATH\" --threads \"$THREADS\" --dynamic-fee-url \"$DYNAMIC_FEE_URL\" --dynamic-fee-max \"$DYNAMIC_FEE_MAX\""
        else
            final_command="ore mine --rpc \"$RPC\" --keypair \"$KEYPAIR_PATH\" --priority-fee \"$ADJUSTED_PRIORITY_FEE\" --threads \"$THREADS\" --buffer-time \"$BUFFER_TIME\""
        fi

        $ECHO -e "Final command: \033[1;32m$final_command\033[0m"

        read -p "Press any key to start mining or CTRL+C to cancel..."

        # Display configuration
        $ECHO -e "\033[0;32mStarting mining operation with the following configuration:\033[0m"
        $ECHO "Cli Version: $ore_version"
        $ECHO "RPC URL: $RPC"
        $ECHO "Keypair Path: $KEYPAIR_PATH"
        $ECHO "Threads: $THREADS"
        $ECHO "Buffer Time: $BUFFER_TIME"
        $ECHO "Wallet Address: $WALLET_ADDRESS"
        if [[ -n "$DYNAMIC_FEE_URL" ]]; then
            $ECHO "Dynamic Fee URL: $DYNAMIC_FEE_URL"
            $ECHO "Maximum Dynamic Fee: $DYNAMIC_FEE_MAX"
        else
            $ECHO "Priority Fee: $ADJUSTED_PRIORITY_FEE"
        fi

        # Run the mining operation
        run_mining
        ;;
    *)
        show_help
        ;;
esac
