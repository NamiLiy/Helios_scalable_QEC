# Filename: calculate_statistics_with_table.py

from collections import defaultdict, Counter
import statistics
import pandas as pd  # For tabular output

def calculate_distributions(file_name):
    # Dictionary to store counts of values for each letter
    distributions = defaultdict(list)

    try:
        # Open and read the file
        with open(file_name, 'r') as file:
            for line in file:
                # Split by comma to get letter and value
                letter, value = line.split(',')
                letter = letter.strip()
                value = int(value.strip())

                # Store the value in the distribution for the letter
                distributions[letter].append(value)

        # Display distributions
        print("Distributions:")
        for letter, values in distributions.items():
            value_counts = Counter(values)
            print(f"{letter}: {dict(value_counts)}")

        # Prepare table for statistical summary
        summary = []
        for letter, values in distributions.items():
            min_value = min(values)
            max_value = max(values)
            mean_value = statistics.mean(values)
            std_dev = statistics.stdev(values) if len(values) > 1 else 0

            # Append data for the table
            summary.append({
                'Letter': letter,
                'Min': min_value,
                'Max': max_value,
                'Mean': round(mean_value, 2),
                'Std Dev': round(std_dev, 2),
            })

        # Create and display the table
        summary_df = pd.DataFrame(summary)

        print("\nStatistical Summary:")
        print(summary_df)

    except FileNotFoundError:
        print(f"Error: The file '{file_name}' does not exist.")
    except ValueError as e:
        print(f"Error: {e}. Please ensure the file is formatted correctly.")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")

# Call the function with the file name
if __name__ == "__main__":
    calculate_distributions('temp01.txt')
