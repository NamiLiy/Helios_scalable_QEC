from collections import defaultdict

# Define the filename
filename = "temp.txt"  # Replace with the actual file name

# Create a dictionary to store the cycle count distribution
cycle_count_distribution = defaultdict(int)
first_round_distribution = defaultdict(int)
second_round_distribution = defaultdict(int)

# Open the file and read the lines
with open(filename, 'r') as file:
    lines = file.readlines()

# Loop through the lines and extract cycle counts
for line in lines:
    parts = line.split()
    #print(parts)
    try:
        cycle_count = int(parts[10])  # 6th entry (0-based index)
        cycle_count_distribution[cycle_count] += 1
        first_round = int(parts[12])
        first_round_distribution[first_round] += 1
        second_round = cycle_count-first_round
        second_round_distribution[second_round] += 1
    except (IndexError, ValueError):
        pass

# Output the cycle count distribution
print("Cycle Count Distribution:")
for cycle_count, count in cycle_count_distribution.items():
    print(f"{cycle_count},{count}")

print("First Round Distribution:")
for first_round, count in first_round_distribution.items():
    print(f"{first_round},{count}")

print("Second Round Distribution:")
for second_round, count in second_round_distribution.items():
    print(f"{second_round},{count}")
