import WatchConnectivity
import Foundation

class iPhoneSessionManager: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = iPhoneSessionManager()

    private let motionService = MotionDataService.shared
    private let motionProcessor = MotionDataProcessor.shared

    @Published private(set) var receivedAccelerations: [Acceleration] = []
    @Published private(set) var receivedQuaternions: [Quaternion] = []

    override private init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
            motionService.stopUpdates()
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
            self.updateContextFromiPhone(value: true)
        }
        
        self.checkMotionDataState()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        print("Checking session reachability!")
        if session.isReachable {
            print("WCSession is reachable.")
        } else {
            print("WCSession is not reachable.")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession became inactive.")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession deactivated. Reactivating...")
        WCSession.default.activate()
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        print("Watch received context: \(applicationContext)")
        DispatchQueue.main.async {
            if let iOSActive = applicationContext["iOSActive"] as? Bool {
                print("Watch updated iOSActive: \(iOSActive)")
            }
            if let watchActive = applicationContext["watchActive"] as? Bool {
                print("Watch updated watchActive: \(watchActive)")
            }
            self.checkMotionDataState()
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleReceivedMessage(message)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        handleReceivedMessage(message)
    }

    // MARK: - Handle Received Messages
    private func handleReceivedMessage(_ message: [String: Any]) {
        if let accelerationData = message["accelerations"] as? [[String: Any]] {
            receivedAccelerations = accelerationData.compactMap {
                guard
                    let x = $0["x"] as? Double,
                    let y = $0["y"] as? Double,
                    let z = $0["z"] as? Double,
                    let timestamp = $0["timestamp"] as? TimeInterval
                else { return nil }
                return Acceleration(x: x, y: y, z: z, timestamp: timestamp)
            }
        }

        if let quaternionData = message["quaternions"] as? [[String: Any]] {
            receivedQuaternions = quaternionData.compactMap {
                guard
                    let w = $0["w"] as? Double,
                    let x = $0["x"] as? Double,
                    let y = $0["y"] as? Double,
                    let z = $0["z"] as? Double,
                    let timestamp = $0["timestamp"] as? TimeInterval
                else { return nil }
                return Quaternion(w: w, x: x, y: y, z: z, timestamp: timestamp)
            }
        }

        motionProcessor.addData(source: "watch", accelerations: receivedAccelerations, quaternions: receivedQuaternions)
    }
    
    // MARK: - Lifecycle Handlers
    func handleAppActivation() {
        print("iOS App became active.")
        self.updateContextFromiPhone(value: true)
        self.checkMotionDataState()
    }

    func handleAppDeactivation() {
        // Application running in the background
        print("2) iOS App will resign active.")
        
        do {
            try WCSession.default.updateApplicationContext(["active": true])
            print("2) Successfully updated context: active = true")
        } catch {
            print("2) Failed to update context: \(error.localizedDescription)")
        }

        checkMotionDataState()
    }

    func handleAppTermination() {
        print("App is terminating.")
        motionService.stopUpdates()
    }
    
    func handleBackgroundTask() {
        motionService.setupMotionUpdates()
    }
    
    func updateContextFromiPhone(value: Bool) {
        let watchActive = (WCSession.default.receivedApplicationContext["watchActive"] as? Bool) ?? false
        
        print("WCSession.default.receivedApplicationContext[\"watchActive\"]: ", WCSession.default.receivedApplicationContext["watchActive"] ?? "Unknown watchActive attribute")
        
        let context: [String: Any] = [
            "iOSActive": value, // Last known value from the iOS app
            "watchActive": watchActive,
        ]
        
        do {
            try WCSession.default.updateApplicationContext(context)
            print("iPhone updated context: \(context)")
        } catch {
            print("Failed to update Watch context: \(error.localizedDescription)")
        }
    }
    
    private func checkMotionDataState() {
        let iOSActive = WCSession.default.applicationContext["iOSActive"] as? Bool ?? false
        let watchActive = WCSession.default.receivedApplicationContext["watchActive"] as? Bool ?? false
        
        // Log the current state
        print("Checking motion data state. iOSActive : \(iOSActive), watchActive: \(watchActive)")

        if iOSActive && watchActive {
            print("Both iOS and Watch apps are active. Starting motion updates.")
            motionService.setupMotionUpdates()
        } else {
            print("Either iOS or Watch app is not active. Stopping motion updates.")
            motionService.stopUpdates()
        }
    }
}
