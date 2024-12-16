import WatchConnectivity
import UIKit

class iPhoneSessionManager: NSObject, WCSessionDelegate {

    static let shared = iPhoneSessionManager()
    private var sessionIsActive = false

    private override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    // MARK: - WCSessionDelegate Methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
        } else {
            print("WCSession activated successfully with state: \(activationState.rawValue)")
            self.sessionIsActive = (activationState == .activated)
        }
        
        if activationState == .activated {
            self.sendiPhoneName() // Send iPhone name on activation
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        self.sessionIsActive = false
        print("WCSession became inactive.")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        self.sessionIsActive = false
        print("WCSession deactivated. Reactivated session.")
        WCSession.default.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            print("WCSession is now reachable.")
        } else {
            print("WCSession is no longer reachable.")
        }
    }

    // Handle incoming messages from the Apple Watch
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        DispatchQueue.main.async {
            self.handleReceivedMessage(message)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            self.handleReceivedMessage(message)
        }
    }

    private func handleReceivedMessage(_ message: [String: Any]) {
        if let coordinatesRec = message["coordinates"] as? [[String: Any]] {
            if coordinatesRec.isEmpty { return }
            
            print("Received last coordinate: ", coordinatesRec.last ?? "No last coordinate")
            
            DispatchQueue.global(qos: .utility).async {
                print("coordinatesRec.count: ", coordinatesRec.count)
                var coordinates: [Acceleration] = []
                
                // Iterate through the received coordinates dictionary
                for coord in coordinatesRec {
                    if let x = coord["x"] as? Double,
                       let y = coord["y"] as? Double,
                       let z = coord["z"] as? Double,
                       let timestampValue = coord["timestamp"] as? Double {
                        print("coord: ", coord)
                        
                        // Convert timestamp to Date
                        let timestamp = Date(timeIntervalSince1970: timestampValue)
                        
                        coordinates.append(Acceleration(x: x, y: y, z: z, timestamp: timestamp))
                    }
                }
                
                DispatchQueue.main.async {
                    print("coordinates sending to be updated count: ", coordinates.count)
                    WatchAccelerometer.shared.updateCoordinates(coordinatesRec: coordinates)
                    
                    // Trigger analysis when 200 coordinates are received
                    if (WatchAccelerometer.shared.coordinates.count == 200) {
                        UnlockManager.shared.unlockIfNeeded()
                    }
                }
            }
        } else if let quaternionsRec = message["quaternions"] as? [[String: Any]] {
            if quaternionsRec.isEmpty { return }
            
            print("Received last quaternion: ", quaternionsRec.last ?? "No last coordinate")
            
            DispatchQueue.global(qos: .utility).async {
                var quaternions: [Quaternion] = []
                                
                for quat in quaternionsRec {
                    if let w = quat["w"] as? Double,
                       let x = quat["x"] as? Double,
                       let y = quat["y"] as? Double,
                       let z = quat["z"] as? Double,
                       let timestampValue = quat["timestamp"] as? Double {
                        print("quat: ", quat)
                        
                        // Convert timestamp to Date
                        let timestamp = Date(timeIntervalSince1970: timestampValue)
                        
                        quaternions.append(Quaternion(w:w, x: x, y: y, z: z, timestamp: timestamp))
                    }
                }
                
                DispatchQueue.main.async {
                    WatchQuaternion.shared.updateQuaternions(quaternions: quaternions)
                    if (WatchQuaternion.shared.quaternionHistory.count == 200) { // When there's a window to be analysed
                        UnlockManager.shared.unlockIfNeeded()
                    }
                }
                
                print("----------------------------------------------------------------------------------------------------")
            }
        }
    }

    // Send current iPhone name to the Apple Watch
    func sendiPhoneName() {
        guard WCSession.default.isReachable else {
            print("Apple Watch is not reachable.")
            return
        }

        let iPhoneName = UIDevice.current.name
        WCSession.default.sendMessage(["iPhoneName": iPhoneName], replyHandler: nil) { error in
            print("Error sending iPhone name: \(error.localizedDescription)")
        }
    }
}
