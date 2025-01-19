import matplotlib.pyplot as plt
import numpy as np

# Given data for watch and iPhone quaternions
watch_quaternions = [
    {"w": 0.99338910981071, "x": -0.08896809767140239, "y": -0.07243631560779627, "z": 0.00395885874141174},
    {"w": 0.9892510901214987, "x": -0.11102670434156024, "y": -0.06304882554321911, "z": 0.07127492368762303},
    {"w": 0.9833627707773328, "x": -0.1161834435776221, "y": -0.04650217047140389, "z": 0.1316681174174741},
    {"w": 0.9797505140962445, "x": -0.11306648203349248, "y": -0.03840059409545206, "z": 0.160717515072507},
    {"w": 0.9816656130913097, "x": -0.11278011973090066, "y": -0.039129235629486996, "z": 0.1486003330867925},
]

iphone_quaternions = [
    {"w": 1.0, "x": -3.3881317890172014e-21, "y": -1.8973538018496328e-19, "z": 0.0},
    {"w": 1.0, "x": -3.3881317890172014e-21, "y": -1.8973538018496328e-19, "z": 0.0},
    {"w": 1.0, "x": -3.3881317890172014e-21, "y": -1.8973538018496328e-19, "z": 0.0},
    {"w": 1.0, "x": -3.3881317890172014e-21, "y": -1.8973538018496328e-19, "z": 0.0},
    {"w": 1.0, "x": -3.3881317890172014e-21, "y": -1.8973538018496328e-19, "z": 0.0},
]

# Normalize quaternions
def normalize_quaternions(quaternions):
    normalized = []
    for q in quaternions:
        norm = np.sqrt(q["w"]**2 + q["x"]**2 + q["y"]**2 + q["z"]**2)
        normalized.append({
            "w": q["w"] / norm,
            "x": q["x"] / norm,
            "y": q["y"] / norm,
            "z": q["z"] / norm,
        })
    return normalized

normalized_watch = normalize_quaternions(watch_quaternions)
normalized_iphone = normalize_quaternions(iphone_quaternions)

# Extract components
def extract_components(quaternions):
    w = [q["w"] for q in quaternions]
    x = [q["x"] for q in quaternions]
    y = [q["y"] for q in quaternions]
    z = [q["z"] for q in quaternions]
    return w, x, y, z

watch_w, watch_x, watch_y, watch_z = extract_components(normalized_watch)
iphone_w, iphone_x, iphone_y, iphone_z = extract_components(normalized_iphone)

# Plot the components
plt.figure(figsize=(12, 6))

# Plot Watch Data
plt.plot(watch_w, label="Watch - W", color="orange", linewidth=2)
plt.plot(watch_x, label="Watch - X", color="red", linewidth=2)
plt.plot(watch_y, label="Watch - Y", color="green", linewidth=2)
plt.plot(watch_z, label="Watch - Z", color="blue", linewidth=2)

# Plot iPhone Data
plt.plot(iphone_w, label="iPhone - W", linestyle="--", color="orange", linewidth=2)
plt.plot(iphone_x, label="iPhone - X", linestyle="--", color="red", linewidth=2)
plt.plot(iphone_y, label="iPhone - Y", linestyle="--", color="green", linewidth=2)
plt.plot(iphone_z, label="iPhone - Z", linestyle="--", color="blue", linewidth=2)

plt.title("Normalized Quaternion Orientation", fontsize=16)
plt.xlabel("Index (or Time)", fontsize=12)
plt.ylabel("Quaternion Components", fontsize=12)
plt.legend(fontsize=10)
plt.grid(alpha=0.5)
plt.ylim([-1.1, 1.1])  # Limit to show normalized values clearly
plt.show()
