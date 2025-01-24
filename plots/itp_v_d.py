import pandas as pd
import matplotlib.pyplot as plt

import pandas as pd
import matplotlib.pyplot as plt

# Load data from file
data_file = "heliosnet_latency_v_d.csv"
df = pd.read_csv(data_file, sep='\t')

# Plotting
plt.figure(figsize=(8, 6))
plt.plot(df['d'], df['ITP/d'], label='inv. throughput', marker='o', linestyle='-', markersize=8)
plt.plot(df['d'], df['(ITP-L)/d'], label='inv. throughput excluding data loading', marker='s', linestyle='-', markersize=8)
plt.xlabel('d')
plt.ylabel('inv. throughput (ns)')
plt.legend()
plt.grid(True)

# Save to PDF
output_file_pdf = "heliosnet_throughput_v_d.pdf"
plt.savefig(output_file_pdf)

# Save to PNG
output_file_png = "heliosnet_throughput_v_d.png"
plt.savefig(output_file_png)

plt.close()

print(f"Chart saved to {output_file_pdf} and {output_file_png}")
