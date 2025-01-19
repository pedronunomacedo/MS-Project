import matplotlib.pyplot as plt
import numpy as np

# Example parameters (replace with actual data)
total_time_seconds = 5 * 60  # Total runtime in seconds (5 minutes)
time_interval_between_unlocks = 2  # Time interval between unlocks in seconds
total_allowed_unlocks = total_time_seconds / time_interval_between_unlocks  # Total negatives and true negatives

# Thresholds and data

## Data for acceleration difference threshold
# accelerations_thresholds = [0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4]
# tp = [0, 4, 6, 7, 8, 9, 10]  # True positives at thresholds
# fp = [0, 2, 2, 2, 3, 3, 4]  # False positives at thresholds
# fn = [6, 1, 1, 1, 1, 1, 1]  # False negatives at thresholds

## Data for acceleration stationary threshold
# accelerations_thresholds = [0.1, 0.12, 0.15, 0.18, 0.20]
# tp = [6, 6, 5, 4, 3]  # True positives at thresholds
# fp = [2, 2, 2, 1, 1]  # False positives at thresholds
# fn = [1, 2, 3, 4, 5]  # False negatives at thresholds

## Data for acceleration stationary threshold
accelerations_thresholds = [0.60, 0.65, 0.70]
tp = [7, 5, 3]  # True positives at thresholds
fp = [2, 3, 4]  # False positives at thresholds
fn = [1, 1, 1]  # False negatives at thresholds

# Calculate total negatives and true negatives
total_negatives = [total_allowed_unlocks - (tp[i] + fn[i]) for i in range(len(tp))]
tn = [total_negatives[i] - fp[i] for i in range(len(fp))]

# Calculate TPR and FPR
tpr = [tp[i] / (tp[i] + fn[i]) for i in range(len(tp))]  # True Positive Rate
fpr = [fp[i] / (fp[i] + tn[i]) for i in range(len(fp))]  # False Positive Rate
fnr = [1 - tpr[i] for i in range(len(tpr))]              # False Negative Rate
tnr = [1 - fpr[i] for i in range(len(fpr))]              # True Negative Rate
eer = [(fpr[i] + fnr[i]) / 2 for i in range(len(fpr))]   # Equal Error Rate

# Debugging output
print("Debugging Metrics:")
for i, threshold in enumerate(accelerations_thresholds):
    print(f"Threshold: {threshold}")
    print(f"  TP: {tp[i]}, FP: {fp[i]}, FN: {fn[i]}, TN: {tn[i]}")
    print(f"  TPR: {tpr[i]:.4f}, FPR: {fpr[i]:.4f}")
    print(f"  FNR: {fnr[i]:.4f}, TNR: {tnr[i]:.4f}")
    print(f"  EER: {eer[i]:.4f}")

# Plot ROC Curve
plt.figure(figsize=(8, 6))
plt.plot(fpr, tpr, label='ROC Curve', marker='o')

# Annotate each point with the threshold
for i, threshold in enumerate(accelerations_thresholds):
    plt.text(fpr[i] + 0.001, tpr[i] + 0.01, f'{threshold:.2f}', fontsize=9)

plt.xlabel('FPR (False Positive Rate)')
plt.ylabel('TPR (True Positive Rate)')
plt.title('ROC Curve with Threshold Annotations')
plt.grid()
plt.legend()
plt.show()

# Plot TPR and FPR vs. Thresholds
plt.figure(figsize=(8, 6))
plt.plot(accelerations_thresholds, tpr, label='TPR', marker='o')
plt.plot(accelerations_thresholds, fpr, label='FPR', marker='o')
plt.xlabel('Thresholds')
plt.ylabel('Rates')
plt.title('TPR and FPR vs. Thresholds')
plt.grid()
plt.legend()
plt.show()

# Plot EER vs. Thresholds
plt.figure(figsize=(8, 6))
plt.plot(accelerations_thresholds, eer, label='EER', marker='o')
plt.xlabel('Thresholds')
plt.ylabel('Equal Error Rate (EER)')
plt.title('EER vs. Thresholds')
plt.grid()
plt.legend()
plt.show()
