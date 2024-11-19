import WatchConnectivity
import UIKit

class iPhoneSessionManager: NSObject, WCSessionDelegate {
    static let shared = iPhoneSessionManager()
    private var sessionIsActive = false
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    // Handle incoming messages from the Apple Watch
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {

        DispatchQueue.main.async {
            // Process the received message as a single dictionary
            if let coordinates = message["coordinates"] as? [String: Any],
                let x = coordinates["x"] as? Double,
                let y = coordinates["y"] as? Double,
                let z = coordinates["z"] as? Double {
                
                let currentTimestamp = Date()
                // Update Apple watch coordinates
                WatchAccelerometer.shared.updateCoordinates(receivedCoordinates: (x: x, y: y, z: z, timestamp: currentTimestamp))
                
                // Check if unlock conditions are met
                UnlockManager.shared.unlockIfNeeded()
                
            } else if let quartenions = message["quaternions"] as? [[String: Any]] {
                DispatchQueue.main.async {
                    // Safely extract each component from the dictionary
                    let w = quartenions.last?["w"] as? Double ?? 0.0
                    let x = quartenions.last?["x"] as? Double ?? 0.0
                    let y = quartenions.last?["y"] as? Double ?? 0.0
                    let z = quartenions.last?["z"] as? Double ?? 0.0
                    let currentTimestamp = Date()
                                        
                    // Update UI or pass to another class as needed
                    WatchQuaternion.shared.updateQuaternions(quaternion: (w: w, x: x, y: y, z: z, timestamp: currentTimestamp))
                    
                    // Check alignment after adding new quaternion
                    // ProcessQuaternions.shared.process()
                    
                    // Check if unlock conditions are met
                    UnlockManager.shared.unlockIfNeeded()
                }
            } else {
                print("WARNING: Received message with unrecognized format.")
            }
        }
    }
    
    // WCSessionDelegate methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
        } else {
            // print("WCSession activated with state: \(activationState)")
            self.sessionIsActive = (activationState == .activated)
        }
        
        if activationState == .activated {
            self.sendiPhoneName() // Send iPhone name on activation
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        self.sessionIsActive = false
        // print("WCSession did become inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        self.sessionIsActive = false
        // print("WCSession did deactivate")
        WCSession.default.activate() // Re-activate the session if needed
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            // print("WCSession is now reachable.")
        } else {
            // print("WCSession is no longer reachable.")
        }
    }
    
    // Send current iPhone name to the Apple watch
    func sendiPhoneName() {
        guard WCSession.default.isReachable else {
            print("Apple watch is not reachable.")
            return
        }
        
        let iPhoneName = UIDevice.current.name
        WCSession.default.sendMessage(["iPhoneName": iPhoneName], replyHandler: nil) { error in
            print("Error sending iPhone name: \(error.localizedDescription)")
        }
    }
}
