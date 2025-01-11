import matplotlib.pyplot as plt
import numpy as np

# Example parameters (replace with actual data)
total_time_seconds = 5 * 60  # Total runtime in seconds (e.g., 5 minutes)
time_interal_between_unlocks = 2  # Time interval between unlocks in seconds
sampling_rate = 0.1  # Sampling rate in seconds
total_samples = total_time_seconds / sampling_rate

accelerations_thresholds = [0.1, 0.2, 0.3]

tp = [0, 7, 7]  # True positives at thresholds
fp = [0, 5, 3]  # False positives at thresholds
fn = [8, 1, 2]  # False negatives at thresholds

# Calculate total negatives and true negatives
total_allowed_unlocks = total_time_seconds / time_interal_between_unlocks

total_negatives = [total_samples - (tp[i] + fn[i]) for i in range(len(tp))]  # Total negatives

tn = [total_negatives[i] - fp[i] for i in range(len(fp))]  # True negatives

# Calculate TPR and FPR
tpr = [tp[i] / (tp[i] + fn[i]) for i in range(len(tp))]  # True Positive Rate
fpr = [fp[i] / (fp[i] + tn[i]) for i in range(len(fp))]  # False Positive Rate
fnr = [1 - tpr[i] for i in range(len(tpr))]              # False Negative Rate

# Find EER (threshold where FPR ≈ FNR)
fpr = np.array(fpr)
fnr = np.array(fnr)
eer_threshold_index = np.argmin(np.abs(fpr - fnr))  # Closest point where FPR ≈ FNR
eer = (fpr[eer_threshold_index] + fnr[eer_threshold_index]) / 2  # Average for interpolation

# Plot ROC curve
plt.plot(fpr, tpr, label='ROC Curve', marker='o')
plt.scatter(fpr[eer_threshold_index], tpr[eer_threshold_index], color='red', label="EER Point")
plt.xlabel('FPR (False Positive Rate)')
plt.ylabel('TPR (True Positive Rate)')
plt.title('ROC Curve')
plt.grid()
plt.legend()
plt.show()

# Print EER and corresponding threshold
print(f"EER: {eer}")
print(f"Threshold at EER: {accelerations_thresholds[eer_threshold_index]}")