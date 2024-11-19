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
        if let coordinates = message["coordinates"] as? [[String: Any]] {
            guard let lastCoordinate = coordinates.last else { return }
            
            DispatchQueue.global(qos: .utility).async {
                let x = lastCoordinate["x"] as? Double ?? 0.0
                let y = lastCoordinate["y"] as? Double ?? 0.0
                let z = lastCoordinate["z"] as? Double ?? 0.0
                let timestamp = lastCoordinate["timestamp"] as? Date ?? Date()
                DispatchQueue.main.async {
                    WatchAccelerometer.shared.updateCoordinates(receivedCoordinate: (x: x, y: y, z: z, timestamp: timestamp))
                    UnlockManager.shared.unlockIfNeeded()
                }
            }
        } else if let quaternions = message["quaternions"] as? [[String: Double]] {
            guard let lastQuaternion = quaternions.last else { return }
            DispatchQueue.global(qos: .utility).async {
                let w = lastQuaternion["w"] ?? 0.0
                let x = lastQuaternion["x"] ?? 0.0
                let y = lastQuaternion["y"] ?? 0.0
                let z = lastQuaternion["z"] ?? 0.0
                let timestamp = Date()
                DispatchQueue.main.async {
                    WatchQuaternion.shared.updateQuaternions(quaternion: (w: w, x: x, y: y, z: z, timestamp: timestamp))
                    UnlockManager.shared.unlockIfNeeded()
                }
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
