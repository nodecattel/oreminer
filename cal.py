#!/usr/bin/env python3

import requests
import numpy as np
from colorama import Fore, Style, init
from tabulate import tabulate
import plot  # Import the updated plot.py with scenario selection
import multiplier
import random
import subprocess

# Initialize colorama
init(autoreset=True)

api_key = "77c5257736a248988068353d034280b0"
sol_address = "So11111111111111111111111111111111111111112"
ore_address = "oreoU2P8bN6jkk3jbaiVxYnG1dCXcYxwhwyK9jSybcp"

def get_token_price(address):
    url = f"https://public-api.birdeye.so/defi/price?address={address}"
    headers = {"X-API-KEY": api_key}
    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        return response.json().get('data', {}).get('value')
    except requests.RequestException:
        return None

def get_ore_rewards():
    try:
        result = subprocess.run(['ore', 'rewards'], capture_output=True, text=True)
        result.check_returncode()
        return {int(line.split(': ')[0]): float(line.split(': ')[1].split()[0])
                for line in result.stdout.strip().split('\n')}
    except Exception:
        return {}

def simulate_one_day(difficulty_levels, probabilities, rewards, ore_price, sol_price, fees_lamports, electric_cost, multiplier):
    fee_sol = (fees_lamports + 5000) / 1e9
    fee_usd = lambda: fee_sol * sol_price + electric_cost / 60
    total_ore, total_profit = 0, 0
    difficulty_hits = {level: 0 for level in difficulty_levels}

    for _ in range(1440):  # 1440 minutes in a day
        difficulty = random.choices(difficulty_levels, weights=probabilities)[0]
        reward = rewards.get(difficulty, 0) * multiplier
        total_ore += reward
        total_profit += reward * ore_price - fee_usd()
        difficulty_hits[difficulty] += 1

    return total_ore, total_profit, difficulty_hits

def display_tiered_summary(hits, rewards, total_passes, multiplier):
    cumulative = 0
    summary_data = []
    for difficulty in sorted(hits):
        percentage = hits[difficulty] / total_passes * 100
        cumulative += percentage
        summary_data.append([
            difficulty,
            f"{rewards.get(difficulty, 0) * multiplier:.8f} ORE/pass",
            hits[difficulty],
            f"{percentage:.1f}%",
            f"{cumulative:.1f}%"
        ])
    print(tabulate(summary_data, headers=["Difficulty", "ORE Reward Rate", "Solves", "Percentage", "Cumulative"], tablefmt="pretty"))

def display_multiplier_preview(stake, top_stake, hits, rewards, ore_price):
    current_multiplier = multiplier.calculate_multiplier(stake, top_stake)
    print(f"{Fore.CYAN}\nMultiplier Preview:")
    print(f"Your Current Stake: {Fore.GREEN}{stake:.8f} ORE{Style.RESET_ALL}")
    print(f"Your Current Multiplier: {Fore.GREEN}{current_multiplier:.8f}{Style.RESET_ALL}")

    preview_data = []
    for increment, new_multiplier in multiplier.preview_multipliers(stake, top_stake):
        percentage_increase = ((new_multiplier - current_multiplier) / current_multiplier) * 100
        expected_ore = sum(hits[difficulty] * rewards.get(difficulty, 0) * new_multiplier for difficulty in hits)
        preview_data.append([f"{stake + increment:.8f} ORE", f"{new_multiplier:.8f}",
                             f"{percentage_increase:.2f}%", f"${increment * ore_price:.2f}",
                             f"{expected_ore:.8f} ORE", f"${expected_ore * ore_price:.6f}"])

    print(tabulate(preview_data, headers=["Stake (ORE)", "Multiplier", "Increase (%)", "Cost of ORE Buy (USD)",
                                          "Expected ORE/Day", "Expected USD/Day"], tablefmt="pretty"))

def main():
    sol_price = get_token_price(sol_address)
    ore_price = get_token_price(ore_address)
    if not sol_price or not ore_price:
        print("Failed to fetch token prices.")
        return

    # Use plot.py to get the difficulty levels and probabilities, including scenario selection
    difficulty_levels, probabilities = plot.get_difficulty_and_probabilities()

    try:
        priority_fees_lamports = int(input(f"{Fore.CYAN}Enter your priority fees in microlamports: {Style.RESET_ALL}") or 0)
        electric_cost_per_hour = float(input(f"{Fore.CYAN}Enter your electricity/rental fees per hour in USD: {Style.RESET_ALL}") or 0.0)
    except ValueError:
        print("Invalid input. Using default values.")
        priority_fees_lamports = 0
        electric_cost_per_hour = 0.0

    rewards = get_ore_rewards()
    stake, top_stake = multiplier.get_stake_and_top_stake()
    multiplier_value = multiplier.calculate_multiplier(stake, top_stake)

    total_ore, total_profit, hits = simulate_one_day(difficulty_levels, probabilities, rewards, ore_price, sol_price,
                                                     priority_fees_lamports, electric_cost_per_hour, multiplier_value)

    print(f"SOL Price: {sol_price}, ORE Price: {ore_price}")
    print(f"Multiplier Applied: {multiplier_value:.8f}")
    print(f"{Fore.YELLOW}\n[Note]\nThis simulation uses a Monte Carlo method to model the mining process over a 24-hour period.")
    print(f"{Fore.YELLOW}Results may vary with each run due to the random nature of the simulation.{Style.RESET_ALL}")

    print(f"{Fore.CYAN}\nDifficulties Solved During 1440 Passes:")
    display_tiered_summary(hits, rewards, 1440, multiplier_value)
    display_multiplier_preview(stake, top_stake, hits, rewards, ore_price)

    fee_sol = priority_fees_lamports / 1e9
    print(f"{Fore.CYAN}\nCost Breakdown:")
    print(f"{Fore.YELLOW}SOL Price: {Style.RESET_ALL}${sol_price:.2f}")
    print(f"{Fore.YELLOW}ORE Price: {Style.RESET_ALL}${ore_price:.2f}")
    print(f"{Fore.YELLOW}Priority Fees: {Style.RESET_ALL}{fee_sol:.8f} SOL per transaction")
    print(f"{Fore.YELLOW}ORE Mining Fee: {Style.RESET_ALL}0.000005 SOL per transaction")
    print(f"{Fore.YELLOW}Electricity/Rental Fees: {Style.RESET_ALL}${electric_cost_per_hour:.2f} per hour")

    print(f"{Fore.CYAN}\nSummary:")
    print(f"Total ORE Mined for the Day: {Fore.GREEN}{total_ore:.8f} ORE{Style.RESET_ALL} | {Fore.GREEN}${total_ore * ore_price:.6f}")
    print(f"Expected ORE Mined for the Day (from probabilities): {Fore.GREEN}{total_ore:.8f} ORE")
    print(f"Total Profit (USD) for the Day: {Fore.GREEN if total_profit >= 0 else Fore.RED}${total_profit:.6f}")
    print(f"Average Profit (USD/hour): {Fore.GREEN if total_profit >= 0 else Fore.RED}${total_profit / 24:.6f}")

if __name__ == "__main__":
    main()
    print(f"{Fore.RED}\nReminder: The results can vary slightly each time due to the Monte Carlo simulation.")
    print(f"The simulation randomly models 1,440 passes (1 per minute) over a 24-hour period, so outcomes might differ with each execution.{Style.RESET_ALL}")
