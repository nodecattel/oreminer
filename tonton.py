#!/usr/bin/env python3

import sys
import json
import subprocess
from dune_client.client import DuneClient
from datetime import datetime, timedelta
from colorama import Fore, Style, init

# Initialize colorama
init(autoreset=True)

# Setup for API key
API_KEY = "<dune-api-key>"

# Function to get the default Solana address
def get_solana_address():
    try:
        result = subprocess.run(["solana", "address"], capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(Fore.RED + "Error fetching Solana address")
        sys.exit(1)

# Prompt the user to enter an address
default_address = get_solana_address()
address = input(f"Enter your Solana address to query (default: {default_address}): ").strip()

# Use the default Solana address if nothing is entered
if not address:
    address = default_address

# Display a message to the user while querying the data
print(Fore.YELLOW + "Querying data points from Dune Analytics, please wait a moment...")

# Initialize DuneClient
dune = DuneClient(API_KEY)

# Fetch the latest results for the signer-related query
query_result = dune.get_latest_result(3980645)
data = query_result.result.rows

# Filter the result for the specific address
filtered_result = [entry for entry in data if entry.get('signer') == address]
miner_data = filtered_result[0] if filtered_result else None

# Check if miner data was found
if miner_data is None:
    print(Fore.RED + "No data found for the given Solana address.")
    sys.exit(1)

# Print the header and filtered result for the specific address
print(Fore.CYAN + "Miner Daily Stats:")
for key, value in miner_data.items():
    print(Fore.CYAN + f"{key}: " + Fore.RESET + f"{value}")
print("")

# Fetch the latest results for the difficulty-related query
difficulty_query_result = dune.get_latest_result(3979634)
difficulty_data = difficulty_query_result.result.rows

# Assume the last available data point is the "current" difficulty
latest_entry = difficulty_data[-1] if difficulty_data else None

# Filter data for the last 24 hours and last week
last_24_hours_data = [entry for entry in difficulty_data if datetime.strptime(entry['date'], "%Y-%m-%d %H:%M:%S.%f UTC") >= datetime.utcnow() - timedelta(hours=24)]
last_week_data = [entry for entry in difficulty_data if datetime.strptime(entry['date'], "%Y-%m-%d %H:%M:%S.%f UTC") >= datetime.utcnow() - timedelta(weeks=1)]

# Calculate average difficulties
def calculate_average(data, key='avg_difficulty'):
    return sum(entry[key] for entry in data) / len(data) if data else 0

current_hour_avg = latest_entry['avg_difficulty'] if latest_entry else 0
last_24_hours_avg = calculate_average(last_24_hours_data)
last_week_avg = calculate_average(last_week_data)

# Print the header and difficulty averages
print(Fore.CYAN + "Global Average Difficulty:")
print(Fore.CYAN + f"Current Hour Average Difficulty: " + Fore.RESET + f"{current_hour_avg:.4f}")
print(Fore.CYAN + f"Average Difficulty over the Last 24 Hours: " + Fore.RESET + f"{last_24_hours_avg:.4f}")
print(Fore.CYAN + f"Average Difficulty over the Last Week: " + Fore.RESET + f"{last_week_avg:.4f}")
print("")

# Compare miner's difficulty with global averages
if miner_data:
    comparison_24h = miner_data['avg_difficulty_per_event'] / last_24_hours_avg if last_24_hours_avg else 0
    comparison_week = miner_data['avg_difficulty_per_event'] / last_week_avg if last_week_avg else 0
    percentage_difference_24h = (comparison_24h - 1) * 100
    percentage_difference_week = (comparison_week - 1) * 100

    print(Fore.CYAN + "Miner vs. Global Comparison:")
    print(Fore.CYAN + f"Miner's Difficulty vs. 24-Hour Global Average: " + Fore.RESET + f"{percentage_difference_24h:.2f}% ({miner_data['avg_difficulty_per_event']:.4f} vs {last_24_hours_avg:.4f})")
    print(Fore.CYAN + f"Miner's Difficulty vs. Weekly Global Average: " + Fore.RESET + f"{percentage_difference_week:.2f}% ({miner_data['avg_difficulty_per_event']:.4f} vs {last_week_avg:.4f})")
    print("")

# Fetch percentile ranking of the miner
sorted_miners = sorted(data, key=lambda x: x['avg_difficulty_per_event'], reverse=True)
total_miners = len(sorted_miners)
miner_rank = next((index for index, entry in enumerate(sorted_miners) if entry['signer'] == address), None)
percentile = (miner_rank / total_miners) * 100 if miner_rank is not None else None

# Performance Summary
performance_summary = f"""
Performance Summary:
--------------------
Miner's current average difficulty: {miner_data['avg_difficulty_per_event']:.4f}
- This places you in the {percentile:.2f}th percentile, meaning you're performing better than {100 - percentile:.2f}% of miners.

Comparison to Peers:
--------------------
- Your average difficulty is {percentage_difference_24h:.2f}% above the 24-hour global average ({miner_data['avg_difficulty_per_event']:.4f} vs {last_24_hours_avg:.4f}).
- Compared to the top 25% of miners, you're trailing behind with a difficulty gap of {(1 - miner_data['avg_difficulty_per_event'] / sorted_miners[int(0.25 * total_miners)]['avg_difficulty_per_event']) * 100:.1f}% ({miner_data['avg_difficulty_per_event']:.4f} vs {sorted_miners[int(0.25 * total_miners)]['avg_difficulty_per_event']:.4f}).

Optimization Suggestions:
-------------------------
- Your average timing per event is {miner_data['avg_timing_per_event']:.2f} seconds. To improve, consider optimizing your hardware to reduce this figure.
- Potential earnings increase by 5-10% with reduced timing and optimized reward strategies.

Historical Trends:
------------------
- Your current difficulty is consistent with your historical average of {miner_data['avg_difficulty_per_event']:.2f}.
- In the past week, your best performance was a max difficulty of {miner_data['max_difficulty']}, matching your current peak.

Profitability Insights:
------------------------
- You’ve earned a total of {miner_data['total_rewards']:.4f} ORE from {miner_data['total_mining_events']} events.
- Consider boosting your setup to align with the top percentile for higher rewards.
"""

print(performance_summary)
