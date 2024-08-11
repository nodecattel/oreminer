#!/usr/bin/env python3

import subprocess

def get_stake_and_top_stake():
    try:
        # Get user's stake from the 'ore balance' command
        balance_output = subprocess.run(['ore', 'balance'], capture_output=True, text=True)
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
        print(f"Your Current Multiplier: {multiplier:.8f}")
        
        print("\nMultiplier Preview for Different Stakes:")
        preview_results = preview_multipliers(stake, top_stake)
        
        for increment, multiplier in preview_results:
            print(f"Stake: {stake + increment:.8f} ORE | Multiplier: {multiplier:.8f}")
    else:
        print("Error: Could not calculate multiplier due to missing stake or top stake.")

if __name__ == "__main__":
    main()
