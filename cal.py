#!/usr/bin/env python3

import requests
import numpy as np
from colorama import Fore, Style, init
from tabulate import tabulate
import plot  # Import the updated plot.py
import multiplier  # Import the multiplier.py
import random
import subprocess

# Initialize colorama
init(autoreset=True)

# Define the API key for BirdEye
api_key = "77c5257736a248988068353d034280b0"

# Define the token addresses
sol_address = "So11111111111111111111111111111111111111112"
ore_address = "oreoU2P8bN6jkk3jbaiVxYnG1dCXcYxwhwyK9jSybcp"

def get_token_price(address):
    url = f"https://public-api.birdeye.so/defi/price?address={address}"
    headers = {"X-API-KEY": api_key}
    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        data = response.json().get('data', {})
        return data.get('value')
    else:
        print(f"Failed to fetch price for address {address}")
        return None

def get_ore_rewards():
    try:
        result = subprocess.run(['ore', 'rewards'], capture_output=True, text=True)
        output = result.stdout.strip()
        rewards = {}
        
        for line in output.split('\n'):
            parts = line.split(': ')
            if len(parts) == 2:
                difficulty = int(parts[0])
                reward = float(parts[1].split()[0])
                rewards[difficulty] = reward
        
        return rewards
    except Exception as e:
        print(f"Failed to execute `ore rewards`: {e}")
        return {}

def simulate_one_day(difficulty_levels, probabilities, rewards, ore_price, sol_price, priority_fees_lamports, electric_cost_per_hour, multiplier):
    ore_mining_fee_lamports = 5000
    total_ore_mined = 0
    total_profit_usd = 0
    
    # Initialize a dictionary to count the hits per difficulty
    difficulty_hits = {level: 0 for level in difficulty_levels}
    
    for minute in range(1440):  # 1440 minutes in a day
        difficulty = random.choices(difficulty_levels, weights=probabilities)[0]
        reward = rewards.get(difficulty, 0) * multiplier  # Apply the multiplier to the reward
        
        ore_mined = reward
        reward_usd = reward * ore_price
        total_fee_lamports = (priority_fees_lamports + ore_mining_fee_lamports)
        total_fee_sol = total_fee_lamports / 1e9
        total_fee_usd = total_fee_sol * sol_price + (electric_cost_per_hour / 60)
        profit_usd = reward_usd - total_fee_usd
        
        # Accumulate daily results
        total_ore_mined += ore_mined
        total_profit_usd += profit_usd
        
        # Record the hit for this difficulty
        difficulty_hits[difficulty] += 1
    
    return total_ore_mined, total_profit_usd, difficulty_hits

def calculate_expected_ore_per_minute(difficulty_levels, probabilities, rewards, multiplier):
    expected_ore_per_minute = sum(p * rewards[d] * multiplier for p, d in zip(probabilities, difficulty_levels))
    return expected_ore_per_minute

def display_tiered_summary(difficulty_hits, rewards, total_passes, multiplier):
    # Prepare data for the tiered summary
    summary_data = []
    cumulative_percentage = 0

    for difficulty, hits in sorted(difficulty_hits.items()):
        percentage = (hits / total_passes) * 100
        cumulative_percentage += percentage
        reward_rate = rewards.get(difficulty, 0) * multiplier
        summary_data.append([difficulty, f"{reward_rate:.8f} ORE/pass", hits, f"{percentage:.1f}%", f"{cumulative_percentage:.1f}%"])
    
    # Display the summary in a table
    summary_table = tabulate(summary_data, headers=["Difficulty", "ORE Reward Rate", "Solves", "Percentage", "Cumulative"], tablefmt="pretty")
    print(summary_table)

def display_multiplier_preview(stake, top_stake, difficulty_hits, rewards, ore_price):
    preview_results = multiplier.preview_multipliers(stake, top_stake)
    
    current_multiplier = multiplier.calculate_multiplier(stake, top_stake)
    print(Fore.CYAN + "\nMultiplier Preview:")
    print(f"Your Current Stake: {Fore.GREEN}{stake:.8f} ORE{Fore.RESET}")
    print(f"Your Current Multiplier: {Fore.GREEN}{current_multiplier:.8f}{Fore.RESET}")
    
    # Prepare data for tabulation
    preview_data = []

    for increment, new_multiplier in preview_results:
        # Calculate the percentage increase in the multiplier
        percentage_increase = ((new_multiplier - current_multiplier) / current_multiplier) * 100
        # Calculate the cost of buying additional ORE
        cost_of_additional_ore = increment * ore_price
        
        # Calculate expected ORE per day using the same difficulty distribution and hits
        expected_ore_per_day = sum(hits * rewards.get(difficulty, 0) * new_multiplier for difficulty, hits in difficulty_hits.items())
        
        # Append the results to the preview_data list
        preview_data.append([
            f"{stake + increment:.8f} ORE", 
            f"{new_multiplier:.8f}", 
            f"{percentage_increase:.2f}%", 
            f"${cost_of_additional_ore:.2f}", 
            f"{expected_ore_per_day:.8f} ORE",
            f"${expected_ore_per_day * ore_price:.6f}"
        ])
    
    # Display the results in a table
    headers = ["Stake (ORE)", "Multiplier", "Increase (%)", "Cost of ORE Buy (USD)", "Expected ORE/Day", "Expected USD/Day"]
    preview_table = tabulate(preview_data, headers=headers, tablefmt="pretty")
    print(preview_table)

def main():
    sol_price = get_token_price(sol_address)
    ore_price = get_token_price(ore_address)
    print(f"SOL Price: {sol_price}, ORE Price: {ore_price}")
    if sol_price is None or ore_price is None:
        return

    # Use plot.py to get the difficulty levels and probabilities
    difficulty_levels, probabilities = plot.get_difficulty_and_probabilities()

    print(Fore.GREEN + "Enter your priority fees in microlamports: ", end="")
    priority_fees_lamports = int(input())
    print(Fore.GREEN + "Enter your electricity/rental fees per hour in USD: ", end="")
    electric_cost_per_hour = float(input())

    # Convert microlamports to SOL correctly
    priority_fees_sol = priority_fees_lamports / 1e8  # Correct conversion for microlamports to SOL

    # Get real ORE rewards for each difficulty level from the `ore rewards` command
    rewards = get_ore_rewards()

    # Get the current stake and top stake
    stake, top_stake = multiplier.get_stake_and_top_stake()

    # Calculate the multiplier based on user's stake and top staker's stake
    multiplier_value = multiplier.calculate_multiplier(stake, top_stake)
    print(f"Multiplier Applied: {multiplier_value:.8f}")

    # Simulate one day of mining using the current multiplier
    total_ore_mined, total_profit_usd, difficulty_hits = simulate_one_day(
        difficulty_levels, probabilities, rewards, ore_price, sol_price, 
        priority_fees_lamports, electric_cost_per_hour, multiplier_value)

    # Remark about the Monte Carlo Simulation
    print(Fore.YELLOW + "\n[Note]")
    print(Fore.YELLOW + "This simulation uses a Monte Carlo method to model the mining process over a 24-hour period.")
    print(Fore.YELLOW + "Each run of this script may yield different results based on the random nature of the simulation.")
    print(Fore.YELLOW + "This helps to account for the inherent variability in mining outcomes.")

    # Display the tiered summary with the current multiplier applied
    print(Fore.CYAN + "\nDifficulties Solved During 1440 Passes:")
    display_tiered_summary(difficulty_hits, rewards, 1440, multiplier_value)

    # Show multiplier preview for different stake increments using the existing difficulty hits
    display_multiplier_preview(stake, top_stake, difficulty_hits, rewards, ore_price)
    
    # Detailed breakdown
    print(Fore.CYAN + "\nCost Breakdown:")
    print(f"{Fore.YELLOW}SOL Price: {Fore.RESET}${sol_price:.2f}")
    print(f"{Fore.YELLOW}ORE Price: {Fore.RESET}${ore_price:.2f}")
    print(f"{Fore.YELLOW}Priority Fees: {Fore.RESET}{priority_fees_sol:.8f} SOL per transaction")
    print(f"{Fore.YELLOW}ORE Mining Fee: {Fore.RESET}0.000005 SOL per transaction")
    print(f"{Fore.YELLOW}Electricity/Rental Fees: {Fore.RESET}${electric_cost_per_hour:.2f} per hour")
    
    print(Fore.CYAN + "\nSummary:")
    print(f"Total ORE Mined for the Day: {Fore.GREEN}{total_ore_mined:.8f} ORE {Fore.RESET}| {Fore.GREEN}${total_ore_mined * ore_price:.6f}")
    print(f"Expected ORE Mined for the Day (from probabilities): {Fore.GREEN}{total_ore_mined:.8f} ORE")
    print(f"Total Profit (USD) for the Day: {Fore.GREEN if total_profit_usd >= 0 else Fore.RED}${total_profit_usd:.6f}")
    print(f"Average Profit (USD/hour): {Fore.GREEN if total_profit_usd >= 0 else Fore.RED}${total_profit_usd / 24:.6f}")

if __name__ == "__main__":
    main()

    # Reminder message printed in red color
    print(Fore.RED + "\nReminder: The results can vary slightly each time due to the Monte Carlo simulation.")
    print(Fore.RED + "The simulation randomly models 1,440 passes (1 per minute) over a 24-hour period, so the outcomes might differ with each execution.")

