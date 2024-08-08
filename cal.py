#!/usr/bin/env python3

import subprocess
import requests
from colorama import Fore, Style, init
from tabulate import tabulate

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

def get_ore_binary_path():
    try:
        result = subprocess.run(['which', 'ore'], capture_output=True, text=True)
        ore_path = result.stdout.strip()
        print(f"ORE binary path: {ore_path}")  # Debug print
        return ore_path
    except Exception as e:
        print(f"Failed to find `ore` binary path: {e}")
        return None

def get_ore_rewards(ore_path):
    try:
        # Execute the `ore rewards` command and capture the output
        result = subprocess.run([ore_path, 'rewards'], capture_output=True, text=True)
        output = result.stdout.strip()
        print("ORE rewards output:", output)  # Debug print
        rewards = {}
        
        # Parse the output into a dictionary
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

def display_rewards_in_usd_per_hour(rewards, ore_price, priority_fees_lamports, sol_price):
    ore_mining_fee_lamports = 50000
    rewards_usd_per_hour = {difficulty: round(reward * ore_price * 60, 8) for difficulty, reward in rewards.items()}
    table = []

    for difficulty, reward in rewards.items():
        reward_usd_per_hour = rewards_usd_per_hour[difficulty]
        total_fee_lamports_per_hour = (priority_fees_lamports + ore_mining_fee_lamports) * 60
        total_fee_sol_per_hour = total_fee_lamports_per_hour / 1e9
        total_fee_usd_per_hour = total_fee_sol_per_hour * sol_price
        profit_usd_per_hour = reward_usd_per_hour - total_fee_usd_per_hour
        profitable = "Yes" if profit_usd_per_hour > 0 else "No"
        table.append([difficulty, reward, reward_usd_per_hour, total_fee_usd_per_hour, profit_usd_per_hour, profitable])

    print(tabulate(table, headers=["Difficulty", "ORE Reward (per min)", "USD Reward (per hour)", "Total Fee (USD/hour)", "Profit (USD/hour)", "Profitable"], tablefmt="pretty"))
    return rewards_usd_per_hour

def calculate_profitability(priority_fees_lamports, average_difficulty, rewards, sol_price, ore_price):
    ore_mining_fee_lamports = 50000
    total_fee_lamports = priority_fees_lamports + ore_mining_fee_lamports
    total_fee_sol = total_fee_lamports / 1e9
    total_fee_usd = total_fee_sol * sol_price
    
    reward_ore = rewards.get(average_difficulty, 0)
    reward_usd = round(reward_ore * ore_price * 60, 8)
    
    profit_usd = reward_usd - total_fee_usd * 60
    profit_usd_per_hour = profit_usd
    total_fee_sol_per_hour = total_fee_sol * 60
    
    return total_fee_usd, reward_usd, profit_usd, profit_usd_per_hour, total_fee_sol_per_hour, reward_ore

def suggest_adjusted_priority_fee(priority_fees_lamports, average_difficulty, rewards, sol_price, ore_price):
    ore_mining_fee_lamports = 50000
    reward_ore = rewards.get(average_difficulty, 0)
    reward_usd_per_hour = round(reward_ore * ore_price * 60, 8)
    total_fee_usd_per_hour = reward_usd_per_hour
    
    total_fee_sol_per_hour = total_fee_usd_per_hour / sol_price
    total_fee_lamports_per_hour = total_fee_sol_per_hour * 1e9
    adjusted_priority_fee_lamports = total_fee_lamports_per_hour / 60 - ore_mining_fee_lamports
    
    if adjusted_priority_fee_lamports < 0:
        adjusted_priority_fee_lamports = 0
    
    return adjusted_priority_fee_lamports

def suggest_ore_price_for_breakeven(priority_fees_lamports, average_difficulty, rewards, sol_price):
    ore_mining_fee_lamports = 50000
    total_fee_lamports = (priority_fees_lamports + ore_mining_fee_lamports) * 60
    total_fee_sol = total_fee_lamports / 1e9
    total_fee_usd = total_fee_sol * sol_price
    reward_ore = rewards.get(average_difficulty, 0)
    ore_price_to_breakeven = total_fee_usd / (reward_ore * 60) if reward_ore > 0 else float('inf')
    
    return ore_price_to_breakeven

def main():
    sol_price = get_token_price(sol_address)
    ore_price = get_token_price(ore_address)
    print(f"SOL Price: {sol_price}, ORE Price: {ore_price}")  # Debug print
    if sol_price is None or ore_price is None:
        return
    
    ore_path = get_ore_binary_path()
    if not ore_path:
        return
    
    rewards = get_ore_rewards(ore_path)
    if not rewards:
        return
    
    print(Fore.GREEN + "Enter your priority fees in microlamports: ", end="")
    priority_fees_lamports = int(input())
    print(Fore.GREEN + "Enter the average landing difficulty: ", end="")
    average_difficulty = int(input())

    rewards_usd_per_hour = display_rewards_in_usd_per_hour(rewards, ore_price, priority_fees_lamports, sol_price)
    
    total_fee_usd, reward_usd, profit_usd, profit_usd_per_hour, total_fee_sol_per_hour, reward_ore = calculate_profitability(priority_fees_lamports, average_difficulty, rewards, sol_price, ore_price)
    
    print(f"Total Mining Fee per hour: {total_fee_sol_per_hour:.8f} SOL | ${total_fee_usd * 60:.8f}")
    print(f"ORE Reward per hour: {reward_ore * 60:.8f} ORE | ${reward_usd:.8f}")
    
    daily_profit_usd = profit_usd_per_hour * 24
    print(f"Daily Profit (USD): ${daily_profit_usd:.8f}")

    if profit_usd_per_hour >= 0:
        print(Fore.GREEN + f"Profit (USD/hour): ${profit_usd_per_hour:.8f}")
    else:
        print(Fore.RED + f"Profit (USD/hour): ${profit_usd_per_hour:.8f}")
        suggested_priority_fee = suggest_adjusted_priority_fee(priority_fees_lamports, average_difficulty, rewards, sol_price, ore_price)
        print(Fore.RED + f"Suggested Priority Fee to be Profitable (lamports): {suggested_priority_fee:.0f}")
        ore_price_to_breakeven = suggest_ore_price_for_breakeven(priority_fees_lamports, average_difficulty, rewards, sol_price)
        print(Fore.RED + f"ORE Price needed to Breakeven: ${ore_price_to_breakeven:.8f}")

if __name__ == "__main__":
    main()
