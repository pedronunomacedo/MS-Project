import WatchKit
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate, WCSessionDelegate, ObservableObject {
    static let shared = ExtensionDelegate()
    @Published var showUnlockNotification: Bool = false
    
    @Published var iPhoneName: String = "None"
    
    func applicationDidFinishLaunching() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    // Handle updated application context from the iPhone
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        // Fetch something from the application context
    }
    
    // Handle incoming messages from the iOS app
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("Received message: \(message)")
            
        if let iPhoneName = message["iPhoneName"] as? String {
            if iPhoneName == ""  {
                return
            }
            
            self.iPhoneName = iPhoneName
        } else if let iphoneUnlockStatus = message["unlockiPhoneStatus"] as? String {
            DispatchQueue.main.async {
                self.showUnlockNotification = (iphoneUnlockStatus == "unlocked")
                print("[DEBUG] self.showUnlockNotification: ", self.showUnlockNotification)
                
                if self.showUnlockNotification {
                    print("Showing unlock iPhone notification on Apple Watch!")
                    // Hide the notification after 5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.showUnlockNotification = false
                        print("[DEBUG - After 5 seconds of overlay] self.showUnlockNotification: ", self.showUnlockNotification)
                    }
                }
            }
        } else {
            print("Received message without expected key or incorrect type")
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
        }
    }
}
