#!/usr/bin/env python3

import numpy as np
import prettytable as pt
import subprocess
import re
from colorama import Fore, Style, init

# Initialize colorama
init(autoreset=True)

def get_hashpower():
    """
    Prompts the user to enter their hashpower per second (Hs) and calculates hashpower per minute (Hm).
    """
    try:
        print(f"{Fore.CYAN}Enter your hashpower per second (Hs):{Style.RESET_ALL}", end=" ")
        Hs = float(input())
        Hm = Hs * 60
        return Hm
    except ValueError:
        print("Invalid input. Please enter a numeric value.")
        return None

def calculate_probabilities(Hm, d1, decay_rate):
    """
    Calculates the probabilities p(d) for each difficulty level using exponential decay for higher difficulties.
    decay_rate controls how quickly the probability decreases for higher difficulties.
    """
    def C(d):
        return (1 - (0.5 ** d)) ** Hm

    # Base probabilities without decay
    p_d = C(d1) - C(d1 - 1)

    # Apply exponential decay to higher difficulties
    exponential_decay = np.exp(-decay_rate * (d1 - np.min(d1)))
    p_d = p_d * exponential_decay

    # Normalize the probabilities so they sum to 1
    p_d /= np.sum(p_d)

    return p_d

def fetch_difficulty_range():
    """
    Fetches the difficulty range from the 'ore rewards' command.
    """
    try:
        command_output = subprocess.check_output(['ore', 'rewards'], text=True)
        difficulty_levels = re.findall(r'^(\d+):', command_output, re.MULTILINE)
        difficulty_levels = list(map(int, difficulty_levels))

        if difficulty_levels:
            return min(difficulty_levels), max(difficulty_levels)
        else:
            return 1, 50  # Default to full range if no levels found
    except subprocess.CalledProcessError as e:
        print("Error running 'ore rewards' command:", e)
        return 1, 50  # Default to full range if command fails

def filter_difficulties(d1, p_d, range_start, range_end):
    """
    Filters the difficulty levels and corresponding probabilities based on the given range.
    """
    filtered_d1 = d1[(d1 >= range_start) & (d1 <= range_end)]
    filtered_p_d = p_d[(d1 >= range_start) & (d1 <= range_end)]
    return filtered_d1, filtered_p_d

def display_difficulty_table(filtered_d1, filtered_p_d):
    """
    Creates and displays a table showing the difficulty levels and corresponding probabilities.
    """
    table = pt.PrettyTable()
    table.field_names = ["Difficulty Level (d1)", "Probability p(d)"]

    for i in range(len(filtered_d1)):
        table.add_row([filtered_d1[i], f"{filtered_p_d[i]:.8f}"])

    print(table)

    X_mean_y_filtered = np.sum(filtered_d1 * filtered_p_d)
    print(f"\nDifficulty Median = {X_mean_y_filtered:.8f}")

def select_scenario():
    """
    Prompts the user to select a scenario and returns the corresponding decay rate.
    """
    print(f"\n{Fore.CYAN}--- Understanding Decay Rate ---{Style.RESET_ALL}")
    print("The decay rate controls how quickly the probability of solving higher difficulties decreases.")
    print("A higher decay rate means that as difficulty increases, the likelihood of solving those higher difficulties drops off more sharply.")
    print(f"Conversely, a lower decay rate means higher difficulties are more likely to be solved.{Style.RESET_ALL}\n")

    print("Select a scenario to set the decay rate:")
    print(f"{Fore.GREEN}Optimistic{Style.RESET_ALL} (decay_rate = 0.05): Higher difficulties are more achievable.")
    print(f"{Fore.CYAN}Normal{Style.RESET_ALL} (decay_rate = 0.1): Balanced approach where higher difficulties are less likely but possible.")
    print(f"{Fore.RED}Pessimistic{Style.RESET_ALL} (decay_rate = 0.2 to 0.3): Higher difficulties are very rare, focusing on lower difficulties.")

    scenario = input("Enter 1, 2, or 3 to select a scenario: ").strip()

    if scenario == "1":
        decay_rate = 0.05
        print(f"\n{Fore.GREEN}You selected the Optimistic scenario.{Style.RESET_ALL} The decay rate is set to 0.05, meaning higher difficulties are somewhat more achievable.")
    elif scenario == "3":
        decay_rate = 0.25  # Example value for pessimistic; you can adjust between 0.2 to 0.3
        print(f"\n{Fore.RED}You selected the Pessimistic scenario.{Style.RESET_ALL} The decay rate is set to 0.25, meaning higher difficulties are significantly less likely.")
    else:
        decay_rate = 0.1  # Default to Normal scenario
        print(f"\n{Fore.CYAN}You selected the Normal scenario.{Style.RESET_ALL} The decay rate is set to 0.1, providing a balanced approach where higher difficulties are less likely but achievable.")

    return decay_rate

def get_difficulty_and_probabilities():
    """
    Function to be called by cal.py to return the difficulty levels and probabilities.
    Includes scenario selection for the decay rate.
    """
    Hm = get_hashpower()
    if Hm is None:
        return None, None

    d1 = np.arange(1, 51)
    decay_rate = select_scenario()  # Prompt the user to select a scenario
    p_d = calculate_probabilities(Hm, d1, decay_rate)

    range_start, range_end = fetch_difficulty_range()
    filtered_d1, filtered_p_d = filter_difficulties(d1, p_d, range_start, range_end)

    return filtered_d1, filtered_p_d

def main():
    """
    The main function to run when executing plot.py directly.
    It prompts the user to select a scenario and displays the difficulty table.
    """
    Hm = get_hashpower()
    if Hm is None:
        return

    d1 = np.arange(1, 51)
    decay_rate = select_scenario()
    p_d = calculate_probabilities(Hm, d1, decay_rate)

    range_start, range_end = fetch_difficulty_range()
    filtered_d1, filtered_p_d = filter_difficulties(d1, p_d, range_start, range_end)

    display_difficulty_table(filtered_d1, filtered_p_d)

if __name__ == "__main__":
    main()
