# Path to the file containing the data
file_path = 'temp005.txt'

# Initialize a dictionary to store the cycle counts
cycle_distribution = {}

# Variables to compute the average
total_cycles = 0
total_entries = 0

# Read the file line by line
with open(file_path, 'r') as file:
    for line in file:
        # Split the line into components based on multiple spaces
        parts = line.split()
        if len(parts) > 4:
            # Extract the cycle count, which is located before the word 'cycles'
            cycle_count = int(parts[5])
            latency = cycle_count*10
            # for i in range(0, 20):
            #     for j in range(0, i//4):
            #         print(f"{latency + 20-i}")

            # for i in range(0, 20):
            #     for j in range(0, i//4):
            #         print(f"{latency -20 + i}")
            
            # Update the distribution dictionary
            if cycle_count in cycle_distribution:
                cycle_distribution[cycle_count] += 1
            else:
                cycle_distribution[cycle_count] = 1
            
            # Add to total cycles and increment total entries
            total_cycles += cycle_count
            total_entries += 1

# Calculate the average cycle count
average_cycles = total_cycles / total_entries if total_entries > 0 else 0


print("cycles, amount")
for cycles, amount in sorted(cycle_distribution.items()):
    print(f"{cycles}, {amount}")


print(f"\nAverage cycle count: {average_cycles:.2f}")
