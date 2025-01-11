import WatchKit
import SwiftUICore
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate, WCSessionDelegate, ObservableObject {
    static let shared = ExtensionDelegate()
    @Published var showUnlockNotification: Bool = true
    @Published var iPhoneName: String = "None"
    @Published var isWatchReachable: Bool = false
    
    @ObservedObject var motionDataService = MotionDataService()
    private var isAppInBackground = false
    private var watchActive = false
    private var iOSActive = false

    func applicationDidFinishLaunching() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }

        // Handle motion data collection
        motionDataService.onBatchReady = { [weak self] accelerations, quaternions in
            self?.sendMotionData(accelerations: accelerations, quaternions: quaternions)
        }
    }

    func applicationDidBecomeActive() {
        print("Watch App became active.")
        self.watchActive = true
        self.isAppInBackground = false
        self.updateContextFromWatch(value: true)
        self.checkMotionDataState()
    }

    func applicationWillResignActive() {
        print("2) Watch App will resign active.")
        watchActive = false
        isAppInBackground = true

        do {
            self.updateContextFromWatch(value: true)
            print("2) Successfully updated context: active = true")
        } catch {
            print("2) Failed to update context: \(error.localizedDescription)")
        }

        checkMotionDataState()
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
            motionDataService.stopUpdates()
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        print("Watch received context: \(applicationContext)")
        DispatchQueue.main.async {
            if let iOSActive = applicationContext["iOSActive"] as? Bool {
                self.iOSActive = iOSActive
                print("Watch updated iOSActive: \(iOSActive)")
            }
            if let watchActive = applicationContext["watchActive"] as? Bool {
                self.watchActive = watchActive
                print("Watch updated watchActive: \(watchActive)")
            }
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

    private func checkMotionDataState() {
        let iOSActive = WCSession.default.receivedApplicationContext["iOSActive"] as? Bool ?? false
        let watchActive = WCSession.default.applicationContext["watchActive"] as? Bool ?? false
        
        // Log the current state
        print("Checking motion data state. iOSActive : \(iOSActive), watchActive: \(watchActive)")
        
        if iOSActive && watchActive {
            print("Both iOS and Watch apps are active. Starting motion updates.")
            motionDataService.setupMotionUpdates()
        } else {
            print("Either iOS or Watch app is not active. Stopping motion updates.")
            motionDataService.stopUpdates()
        }
    }
    
    func updateContextFromWatch(value: Bool) {
        let currentContext = WCSession.default.applicationContext
        
        let context: [String: Any] = [
            "iOSActive": (currentContext["iOSActive"] as? Int == 1), // Last known value from the iOS app
            "watchActive": value,
        ]
        
        do {
            try WCSession.default.updateApplicationContext(context)
            print("Watch updated context: \(context)")
        } catch {
            print("Failed to update Watch context: \(error.localizedDescription)")
        }
    }

    func sendMotionData(accelerations: [Acceleration], quaternions: [Quaternion]) {
        let content: [String: Any] = [
            "accelerations": accelerations.map { ["x": $0.x, "y": $0.y, "z": $0.z, "timestamp": $0.timestamp] },
            "quaternions": quaternions.map { ["w": $0.w, "x": $0.x, "y": $0.y, "z": $0.z, "timestamp": $0.timestamp] }
        ]
        print("Send motion Data function!")
        sendMessage(content: content)
    }

    func sendMessage(content: [String: Any]) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(content, replyHandler: { response in
                print("3) Motion data sent successfully.")
            }, errorHandler: { error in
                print("3) Error sending motion data: \(error.localizedDescription)")
            })
        } else {
            do {
                try WCSession.default.updateApplicationContext(["active": true])
                print("3) Successfully updated context: active = true")
            } catch {
                print("3) Failed to update context: \(error.localizedDescription)")
            }
        }
    }
}
