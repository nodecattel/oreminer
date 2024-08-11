#!/usr/bin/env python3

import numpy as np
import prettytable as pt
import subprocess
import re

# Input your ORE benchmark results in H/s (Hashpower per second)
Hs = float(input("Enter your hashpower per second (Hs): "))

# Calculate Hm (Hashpower per minute)
Hm = Hs * 60

# Define the difficulty levels (d1)
d1 = np.arange(1, 51)  # 50 difficulty levels from 1 to 50

# Calculate C(d) using the provided formula
def C(d):
    return (1 - (0.5 ** d)) ** Hm

# Calculate p(d) as the difference C(d) - C(d-1)
p_d = C(d1) - C(d1 - 1)

# Fetch difficulty range from 'ore rewards' command
try:
    command_output = subprocess.check_output(['ore', 'rewards'], text=True)
    # Extract all difficulty levels from the command output
    difficulty_levels = re.findall(r'^(\d+):', command_output, re.MULTILINE)
    difficulty_levels = list(map(int, difficulty_levels))
    
    if difficulty_levels:
        range_start = min(difficulty_levels)
        range_end = max(difficulty_levels)
    else:
        range_start, range_end = 1, 50  # Default to full range if no levels found
except subprocess.CalledProcessError as e:
    print("Error running 'ore rewards' command:", e)
    range_start, range_end = 1, 50  # Default to full range if command fails

# Filter the difficulty levels based on the command output
filtered_d1 = d1[(d1 >= range_start) & (d1 <= range_end)]
filtered_p_d = p_d[(d1 >= range_start) & (d1 <= range_end)]

# Create a table to display the results
def display_difficulty_table():
    table = pt.PrettyTable()
    table.field_names = ["Difficulty Level (d1)", "Probability p(d)"]

    # Populate the table with filtered data
    for i in range(len(filtered_d1)):
        table.add_row([filtered_d1[i], f"{filtered_p_d[i]:.8f}"])

    # Print the table
    print(table)

    # Display the calculated Difficulty Median (X_mean(y)) for the filtered range
    X_mean_y_filtered = np.sum(filtered_d1 * filtered_p_d)
    print(f"\nDifficulty Median = {X_mean_y_filtered:.8f}")
    return filtered_d1, filtered_p_d

# New function to be called by cal.py
def get_difficulty_and_probabilities():
    return filtered_d1, filtered_p_d

# If this script is executed directly, display the table
if __name__ == "__main__":
    display_difficulty_table()
