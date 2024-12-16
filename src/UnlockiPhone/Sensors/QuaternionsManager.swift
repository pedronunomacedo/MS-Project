import UIKit
import CoreMotion
import WatchConnectivity

class QuaternionsManager: NSObject, ObservableObject {
    static let shared = QuaternionsManager()  // Singleton instance

    private var motion = CMMotionManager()      // CoreMotion Manager
    private var session: WCSession?             // Watch Connectivity session

    // Store an array of quaternions to capture movement over time
    public private(set) var quaternionHistory: [Quaternion] = []

    override init() {
        super.init()
        startDeviceMotionUpdates()
    }

    // Start Device Motion Updates (which includes quaternion data)
    func startDeviceMotionUpdates() {
        if self.motion.isDeviceMotionAvailable {
            self.motion.deviceMotionUpdateInterval = 1.0 / 50.0  // 50 Hz

            // Start device motion updates
            self.motion.startDeviceMotionUpdates(to: .main) { [weak self] (motionData, error) in
                guard let strongSelf = self, let motion = motionData else {
                    print("Error: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                // Collect quaternion data
                let quaternion = motion.attitude.quaternion
                let w = quaternion.w
                let x = quaternion.x
                let y = quaternion.y
                let z = quaternion.z
                let timestamp = Date()

                // Store the quaternion in the history array
                DispatchQueue.main.async {
                    strongSelf.updateQuaternions(w: w, x: x, y: y, z: z, timestamp: timestamp)
                }
            }
        } else {
            print("Device Motion is not available on this iPhone.")
        }
    }

    // Add last iPhone quaternion to the quaternions list (quaternions data)
    func updateQuaternions(w:Double, x: Double, y: Double, z: Double, timestamp: Date) {
        let quaternion = Quaternion(w: w, x: x, y: y, z: z, timestamp: timestamp)
        self.quaternionHistory.append(quaternion)
        
        // Limit the history size to save memory (we will only keep the last 200 quaternions)
        if self.quaternionHistory.count > 200 {
            self.quaternionHistory.removeFirst()
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
        // print("WCSession did become inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        // print("WCSession did deactivate")
        // Re-activate the session
        WCSession.default.activate()
    }

    // Stop Device Motion Updates
    func stopDeviceMotionUpdates() {
        motion.stopDeviceMotionUpdates()
    }
}
