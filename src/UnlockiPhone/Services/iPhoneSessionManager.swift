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
        // Delay to allow for context synchronization
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.checkMotionDataState()
        }
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
        print("iPhone received context: \(applicationContext)")
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
        handleReceivedMessage(message, replyHandler: nil)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        handleReceivedMessage(message, replyHandler: replyHandler)
    }

    // MARK: - Handle Received Messages
    private func handleReceivedMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)?) {
        if let accelerationData = message["accelerations"] as? [[String: Any]] {
            let processedAccelerations = accelerationData.compactMap { dataDict -> Acceleration? in
                guard
                    let x = dataDict["x"] as? Double,
                    let y = dataDict["y"] as? Double,
                    let z = dataDict["z"] as? Double,
                    let timestamp = dataDict["timestamp"] as? TimeInterval
                else { return nil }
                return Acceleration(x: x, y: y, z: z, timestamp: timestamp)
            }
            DispatchQueue.main.async {
                self.receivedAccelerations = processedAccelerations
            }
        }

        if let quaternionData = message["quaternions"] as? [[String: Any]] {
            let processedQuaternions = quaternionData.compactMap { dataDict -> Quaternion? in
                guard
                    let w = dataDict["w"] as? Double,
                    let x = dataDict["x"] as? Double,
                    let y = dataDict["y"] as? Double,
                    let z = dataDict["z"] as? Double,
                    let timestamp = dataDict["timestamp"] as? TimeInterval
                else { return nil }
                return Quaternion(w: w, x: x, y: y, z: z, timestamp: timestamp)
            }
            DispatchQueue.main.async { [weak self] in
                self?.receivedQuaternions = processedQuaternions
            }
        }
        
        if let requestContext = message["requestContext"] as? Bool, requestContext == true {
            let context: [String: Any] = [
                "iOSActive": true,
                "watchActive": WCSession.default.receivedApplicationContext["watchActive"] as? Bool ?? false
            ]
            if let replyHandler = replyHandler {
                replyHandler(context)
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
        
        self.updateContextFromiPhone(value: true)

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
            print("Failed to update context on iPhone: \(error.localizedDescription)")
                    
            // Use sendMessage as a fallback
            if WCSession.default.isReachable {
                WCSession.default.sendMessage(context, replyHandler: nil, errorHandler: { error in
                    print("Error sending fallback message: \(error.localizedDescription)")
                })
            }
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
