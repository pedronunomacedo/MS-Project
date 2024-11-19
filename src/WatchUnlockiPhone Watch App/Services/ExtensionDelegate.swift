import WatchKit
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate, WCSessionDelegate, ObservableObject {
    static let shared = ExtensionDelegate()
    @Published var iPhoneName: String = "No iPhone connected"
    @Published var showUnlockNotification: Bool = false
    
    func applicationDidFinishLaunching() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    // Handle updated application context from the iPhone
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            if let name = applicationContext["iPhoneName"] as? String {
                self.iPhoneName = name
            } else {
                // print("-> Received applicationContext without iPhone name.")
            }
        }
    }
    
    // Handle incoming messages from the iOS app
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let name = message["iPhoneName"] as? String {
            DispatchQueue.main.async {
                self.iPhoneName = name
            }
        } else if let iphoneUnlockStatus = message["unlockiPhoneStatus"] as? String {
            if iphoneUnlockStatus == "unlocked" {
                DispatchQueue.main.async {
                    self.showUnlockNotification = true
                    // Hide the notification after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.showUnlockNotification = false
                    }
                }
            }
        }
    }
    
    // Implement required WCSessionDelegate methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Handle activation completion
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
            if activationState == .activated {
                print("WCSession is fully activated on the watch.")
                
                // Manually check for the existing applicationContext
                if let name = session.receivedApplicationContext["iPhoneName"] as? String {
                    DispatchQueue.main.async {
                        self.iPhoneName = name
                    }
                }
            }
        }
    }
    
    func sendMessage(content: [String: Any]) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(content, replyHandler: { response in
                print("Message delivered successfully. Response: \(response)")
            }, errorHandler: { error in
                print("Error sending message: \(error.localizedDescription)")
            })
        } else {
            // print("iPhone is not reachable.") 
        }
    }
}
