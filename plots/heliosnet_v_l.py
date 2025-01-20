import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches

# Load data from CSV
file_path = "heliosnet_latency_v_l.csv"
data = pd.read_csv(file_path, sep='\t')

# Extract data columns
d = data['l']
mean = data['Mean']
comm = data['comm']
min_a = data['mn_a']
P95 = data['P95']

# Generate evenly spaced x-positions for bars
x_positions = range(len(d))  # Use evenly spaced positions for bars
bar_width = 0.5  # Set the width of the bars (smaller value for thinner bars)

# Create the plot
plt.figure(figsize=(8, 5))

# Plot bars
bars_mean = plt.bar(x_positions, mean, width=bar_width, color='skyblue', edgecolor='black', label="Decoder Units")
bars_comm = plt.bar(x_positions, comm, width=bar_width, bottom=mean, color='orange', edgecolor='black', label="Communication", hatch='\\')

# Add capped error bars
plt.errorbar(
    x_positions, [m + c for m, c in zip(mean, comm)],
    yerr=[
        [m + c - ma for m, c, ma in zip(mean, comm, min_a)],
        [p - (m + c) for m, c, p in zip(mean, comm, P95)]
    ],
    fmt='none', ecolor='black', capsize=10, capthick=1.5, elinewidth=1.5
)

# Add legend
decoder_patch = mpatches.Patch(facecolor='skyblue', edgecolor='black', label="Decoder Units")
comm_patch = mpatches.Patch(facecolor='orange', edgecolor='black', hatch='\\', label="Communication")
plt.legend(handles=[decoder_patch, comm_patch], loc='upper left')

# Customize labels and ticks
plt.xlabel("# of logical qubits")
plt.ylabel("Latency (ns)")
plt.xticks(ticks=x_positions, labels=d)  # Set ticks at bar positions with logical qubit labels
plt.xlim(-0.5, len(d) - 0.5)  # Limit x-axis range to match the number of bars
plt.grid(axis='y', linestyle='--', alpha=0.7)

# Save the plot as a PDF
output_path = "heliosnet_latency_v_l.pdf"
plt.savefig(output_path, format='pdf')
plt.close()

print(f"Plot saved as {output_path}")
