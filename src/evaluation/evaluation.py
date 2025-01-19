from scipy.interpolate import interp1d
import numpy as np
import matplotlib.pyplot as plt

# Extended threshold values
thresholds = [0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.50]

# Given data for FRR and FAR
frr_m1 = np.array([0.80, 0.59, 0.47, 0.40, 0.32, 0.13, 0.08])  # Convert to numpy array
far_m1 = np.array([0.00, 0.00, 0.05, 0.13, 0.18, 0.22, 0.24])  # Convert to numpy array

# Interpolate FRR and FAR values to find the intersection point (EER)
frr_interp = interp1d(thresholds, frr_m1, kind='linear')
far_interp = interp1d(thresholds, far_m1, kind='linear')

# Find the intersection point (threshold where FRR == FAR)
threshold_range = np.linspace(min(thresholds), max(thresholds), 500)
frr_values = frr_interp(threshold_range)
far_values = far_interp(threshold_range)

# Find the EER (where the absolute difference between FRR and FAR is minimal)
eer_index = np.argmin(np.abs(frr_values - far_values))
eer_threshold = threshold_range[eer_index]
eer_rate = frr_values[eer_index]  # Equal to FAR at this point

# Plotting the graph again with the exact EER marked
plt.figure(figsize=(10, 6))

# Plot FRR for M1
plt.plot(thresholds, frr_m1, marker='o', label='FRR')

# Plot FAR for M1
plt.plot(thresholds, far_m1, marker='x', label='FAR')

# Mark the EER point
plt.scatter(eer_threshold, eer_rate, color='red', label=f'EER ({eer_threshold:.2f}, {eer_rate:.2f})', zorder=5)

# Graph details
plt.title("FRR and FAR vs Threshold (With Exact EER Marked)")
plt.xlabel("Threshold")
plt.ylabel("Rate")
plt.grid(True)
plt.legend()
plt.show()

# Print the EER
print(f"EER Threshold: {eer_threshold:.2f}, EER Rate: {eer_rate:.2f}")