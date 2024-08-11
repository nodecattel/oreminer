#!/usr/bin/env python3

import subprocess
import os

def get_keypair_path():
    try:
        # Try to get the keypair path from ore.conf
        with open(os.path.expanduser("~/.ore/ore.conf"), "r") as conf_file:
            for line in conf_file:
                if line.startswith("KEYPAIR_PATH="):
                    return line.split("=")[1].strip()
        
        # If not found in ore.conf, get it from Solana config
        solana_config_output = subprocess.run(
            ['solana', 'config', 'get'],
            capture_output=True, text=True
        )
        for line in solana_config_output.stdout.strip().split('\n'):
            if "Keypair Path:" in line:
                return line.split(":")[1].strip()
        
    except Exception as e:
        print(f"Failed to retrieve keypair path: {e}")
        return None

def get_stake_and_top_stake():
    try:
        keypair_path = get_keypair_path()
        if keypair_path:
            # Get user's stake from the 'ore balance' command with the keypair option
            balance_output = subprocess.run(
                ['ore', 'balance', '--keypair', keypair_path], 
                capture_output=True, text=True
            )
            balance_lines = balance_output.stdout.strip().split('\n')

            stake = 0
            for line in balance_lines:
                if "Stake:" in line:
                    stake = float(line.split(":")[1].strip().split()[0])
                    break

            # Get top staker's stake from the 'ore config' command
            config_output = subprocess.run(['ore', 'config'], capture_output=True, text=True)
            config_lines = config_output.stdout.strip().split('\n')

            top_stake = 0
            for line in config_lines:
                if "Top stake:" in line:
                    top_stake = float(line.split(":")[1].strip().split()[0])
                    break

            return stake, top_stake
        else:
            print("Error: Keypair path not found in ore.conf or Solana config.")
            return None, None

    except Exception as e:
        print(f"Failed to retrieve stake information: {e}")
        return None, None

def calculate_multiplier(stake, top_stake):
    if stake is None or top_stake is None or top_stake == 0:
        return 1  # If there's an issue, return a neutral multiplier of 1
    multiplier = 1 + (stake / top_stake)
    return multiplier

def preview_multipliers(stake, top_stake):
    increments = [1, 5, 10, 15, 20, 50, 100]
    preview_results = []
    
    for increment in increments:
        new_stake = stake + increment
        multiplier = calculate_multiplier(new_stake, top_stake)
        preview_results.append((increment, multiplier))
    
    return preview_results

def main():
    stake, top_stake = get_stake_and_top_stake()
    if stake is not None and top_stake is not None:
        multiplier = calculate_multiplier(stake, top_stake)
        print(f"Stake: {stake:.12f} ORE")
        print(f"Your Current Multiplier: {multiplier:.8f}")
        
        print("\nMultiplier Preview for Different Stakes:")
        preview_results = preview_multipliers(stake, top_stake)
        
        for increment, multiplier in preview_results:
            print(f"Stake: {stake + increment:.12f} ORE | Multiplier: {multiplier:.8f}")
    else:
        print("Error: Could not calculate multiplier due to missing stake or top stake.")

if __name__ == "__main__":
    main()
