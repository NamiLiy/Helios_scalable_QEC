from collections import defaultdict

# Define the filename
filename = "temp.txt"  # Replace with the actual file name

# Create a dictionary to store the cycle count distribution
cycle_count_distribution = defaultdict(int)

# Open the file and read the lines
with open(filename, 'r') as file:
    lines = file.readlines()

# Loop through the lines and extract cycle counts
for line in lines:
    parts = line.split()
    try:
        cycle_count = int(parts[5])  # 6th entry (0-based index)
        cycle_count_distribution[cycle_count] += 1
    except (IndexError, ValueError):
        pass

# Output the cycle count distribution
print("Cycle Count Distribution:")
for cycle_count, count in cycle_count_distribution.items():
    print(f"{cycle_count},{count}")
