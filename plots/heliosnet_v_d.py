import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches

# Load data from CSV
file_path = "heliosnet_latency_v_d.csv"
data = pd.read_csv(file_path, sep='\t')

# Extract data columns
d = data['d']
mean = data['Mean']
comm = data['comm']
min_a = data['mn_a']
P95 = data['P95']

# Create the plot
plt.figure(figsize=(8, 5))

# Plot bars
bars_mean = plt.bar(d, mean, color='skyblue', edgecolor='black', label="Decoder Units")
bars_comm = plt.bar(d, comm, bottom=mean, color='orange', edgecolor='black', label="Communication", hatch='\\')

# Add capped error bars
plt.errorbar(
    d, [m + c for m, c in zip(mean, comm)],
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
plt.xlabel("d")
plt.ylabel("Latency (ns)")
plt.xticks([5, 7, 9, 11])  # Show only odd numbers from 4 to 12
plt.xlim(4, 12)  # Limit x-axis range
plt.grid(axis='y', linestyle='--', alpha=0.7)

# Save the plot as a PDF
# output_path = "heliosnet_latency_v_d.pdf"
# plt.savefig(output_path, format='pdf')
# plt.close()

output_path = "heliosnet_latency_v_d.png"
plt.savefig(output_path, format='png')
plt.close()

print(f"Plot saved as {output_path}")
