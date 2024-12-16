import UIKit
import CoreMotion
import WatchConnectivity

class AccelerometerManager: NSObject, ObservableObject {
    static let shared = AccelerometerManager()  // Singleton instance

    private var motion = CMMotionManager()      // CoreMotion Manager
    private var session: WCSession?             // Watch Connectivity session

    // public private(set) var coordinates: [String: Any] = ["x": 0.0, "y": 0.0, "z": 0.0, "timestamp": Date()] // Current iPhone coordinates
    @Published var coordinates: [Acceleration] = [] // Current Apple watch coordinates

    override init() {
        super.init()
        startAccelerometers()
    }

    // Start Accelerometer Updates
    func startAccelerometers() {
        if self.motion.isAccelerometerAvailable {
            self.motion.accelerometerUpdateInterval = 1.0 / 50.0  // 50 Hz

            // Start accelerometer updates
            self.motion.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
                guard let strongSelf = self, let accelerometerData = data else {
                    print("Error: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                let x = accelerometerData.acceleration.x
                let y = accelerometerData.acceleration.y
                let z = accelerometerData.acceleration.z
                let currentTimestamp = Date()

                // Ensure updates to published properties are handled on the main thread
                DispatchQueue.main.async {
                    strongSelf.updateCoordinates(x: x, y: y, z: z, timestamp: currentTimestamp)
                }
            }
        } else {
            print("Accelerometer is not available on this iPhone.")
        }
    }

    // Update iphone Coordinates
    func updateCoordinates(x: Double, y: Double, z: Double, timestamp: Date) {
        let acceleration = Acceleration(x: x, y: y, z: z, timestamp: timestamp)
        coordinates.append(acceleration)
        
        // Limit the array size if needed to avoid excessive memory usage
        if coordinates.count > 200 { // For example, keep only the latest 200 samples (0.02 * 200 = 4 seconds)
            coordinates.removeFirst()
        }
    }

    // WCSessionDelegate methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession did become inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession did deactivate")
        // Re-activate the session
        WCSession.default.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        print("WCSession reachability changed: \(session.isReachable)")
    }

    // Stop Accelerometer Updates
    func stopAccelerometers() {
        motion.stopAccelerometerUpdates()
    }
}
