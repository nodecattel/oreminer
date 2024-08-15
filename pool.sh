#!/bin/bash
source ~/.profile

echo -e "\033[0;32m"
cat << "EOF"
█▀█ █▀█ █▀▀ █▀▄▀█ █ █▄░█ █▀▀ █▀█
█▄█ █▀▄ ██▄ █░▀░█ █ █░▀█ ██▄ █▀▄ ORE V2 - 2.3.0 mainnet
EOF
echo -e "Version 0.1.5 - NodeCattel Alvarium Pool Client"
echo -e "Made by NodeCattel & All the credits to HardhatChad\033[0m"

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
if [ $? -ne 0 ]; then
    echo -e "\033[0;31mError installing required packages. Exiting...\033[0m"
    exit 1
fi

# Check if ore.conf exists, if not, create it with default values
config_file="$HOME/.ore/ore.conf"
if [ ! -f "$config_file" ]; then
    echo -e "\033[0;32m\nore.conf not found. Creating default ore.conf...\033[0m"
    mkdir -p "$HOME/.ore"
    cat > "$config_file" << EOL
RPC=$DEFAULT_RPC
PRIORITY_FEE=$BASE_PRIORITY_FEE
CORES=$DEFAULT_CORES
KEYPAIR_PATH=$DEFAULT_KEYPAIR_PATH
BUFFER_TIME=$DEFAULT_BUFFER_TIME
DYNAMIC_FEE_URL=
JITO_ENABLED=$DEFAULT_JITO_ENABLED
EOL
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
if [ $? -ne 0 ]; then
    echo -e "\033[0;31mError updating ore-pool-miner repository. Exiting...\033[0m"
    exit 1
fi

# Build the ore-pool-miner project
cargo build --release
if [ $? -ne 0 ]; then
    echo -e "\033[0;31mError building ore-pool-miner. Exiting...\033[0m"
    exit 1
fi

# Copy the binary to Cargo bin directory
echo -e "\033[0;32m\nCopying the binary to Cargo bin directory...\033[0m"
cp target/release/alvarium ~/.cargo/bin/
if [ $? -ne 0 ]; then
    echo -e "\033[0;31mError copying alvarium binary. Exiting...\033[0m"
    exit 1
fi

# Load values from ore.conf
RPC_URL=$(grep 'RPC' "$config_file" | cut -d'=' -f2 | xargs)
CORES=$(grep 'CORES' "$config_file" | cut -d'=' -f2 | xargs)
BUFFER_TIME=8  # Set buffer time to 8 as recommended by Alvarium Pool Mine
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

echo -e "\033[0m\nBuffer Time (Alvarium recommended: 8 seconds):\033[0;32m"
read -p "Press Enter to confirm or enter a different buffer time: " input_buffer
if [[ -n "$input_buffer" ]]; then
    BUFFER_TIME="$input_buffer"
fi

# Checking ORE balance in the pool
echo -e "\n\nChecking ORE balance in the pool for wallet $WALLET_ADDRESS..."
RESPONSE=$(curl -s --max-time 10 "https://alvarium.bifrost.technology/balance?miner=$WALLET_ADDRESS")

BALANCE_RAW=$(echo $RESPONSE | grep -oP '(?<="value":)[0-9]+')

if [[ -z "$BALANCE_RAW" ]]; then
    echo -e "\033[0;31mBalance not found or miner has not started yet.\033[0m"
else
    # Convert to ORE balance
    ORE_BALANCE=$(echo "scale=8; $BALANCE_RAW / 100000000000" | bc)
    echo -e "\033[0;32mORE Balance in Pool for wallet $WALLET_ADDRESS: $ORE_BALANCE ORE\033[0m"
    
    # Display the warning message in red
    echo -e "\033[0;31m"
    echo "You must have ORE in your wallet to claim."
    echo "ORE program won't pay for your token account creation!!"
    echo "Minimum bank balance to claim: 0.001 ORE"
    echo -e "\033[0m" # Reset color

    # Prompt the user to confirm if they want to proceed with claiming
    read -p "Do you want to proceed with claiming your ORE in the pool? [y/N]: " proceed

    if [[ "$proceed" =~ ^[Yy]$ ]]; then
        # Perform the claim
        echo "Attempting to claim ORE..."
        CLAIM_RESPONSE=$(curl -s --max-time 10 "https://alvarium.bifrost.technology/claim?miner=$WALLET_ADDRESS")
        echo "Claim response: $CLAIM_RESPONSE"
    else
        echo "Claim process canceled."
    fi
fi

# Ensure the script continues to the final command
echo -e "\033[0;32mProceeding to the final command...\033[0m"

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
