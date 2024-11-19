import UIKit
import WatchConnectivity
import BackgroundTasks

class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate, UNUserNotificationCenterDelegate {
    
    let taskID = "Uni.FRI.UnlockiPhoneApplication.backgroundTask"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self  // Set the delegate
            session.activate()
        }
        
        UNUserNotificationCenter.current().delegate = self
        
        // Ensure the iPhoneSessionManager is initialized
        _ = iPhoneSessionManager.shared
        
        // Deal with background task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskID, using: nil) { task in
            // Handle the task when it runs
            guard let task = task as? BGAppRefreshTask else { return }
            self.handleTask(task: task)
        }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
        
        requestNotificationAuthorization() // Notification to request permission to send notifications
        
        schedule()
        
        return true
    }
    
    private func handleTask(task: BGAppRefreshTask) {
        
    }
    
    private func schedule() {
        // SUbmit a task to be scheduled
        do {
            let newTask = BGAppRefreshTaskRequest(identifier: taskID)
            try BGTaskScheduler.shared.submit(newTask)
        } catch {
            // ignore
        }
    }
    
    // Handle messages from the Apple Watch that expect a reply
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
//        if let request = message["request"] as? String, request == "iPhoneName" {
//            // Get the iPhone's name
//            let iPhoneName = UIDevice.current.name
//            // Send the name back as a response
//            replyHandler(["iPhoneName": iPhoneName])
//        } else {
//            print("Received an unrecognized message: \(message)")
//        }
    }
    
    // Method for handling messages that do not expect a reply
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        // Post the message to the notifications service
        if let coordinates = message["coordinates"] as? [String: Any] {
            DispatchQueue.main.async {
                // Update UI or pass to another class as needed
                WatchAccelerometer.shared.updateCoordinates(receivedCoordinates: (x: coordinates["x"] as? Double ?? 0.0, y: coordinates["y"] as? Double ?? 0.0, z: coordinates["z"] as? Double ?? 0.0, timestamp: coordinates["timestamp"] as! Date ))
                
                // Check if unlock conditions are met
                UnlockManager.shared.unlockIfNeeded()
            }
        } else if let quartenions = message["quaternions"] as? [[String: Double]] {
            DispatchQueue.main.async {
                // Safely extract each component from the dictionary
                let w = quartenions.last?["w"] as? Double ?? 0.0
                let x = quartenions.last?["x"] as? Double ?? 0.0
                let y = quartenions.last?["y"] as? Double ?? 0.0
                let z = quartenions.last?["z"] as? Double ?? 0.0
                let currentTimestamp = Date()
                                
                // Update UI or pass to another class as needed
                WatchQuaternion.shared.updateQuaternions(quaternion: (w: w, x: x, y: y, z: z, timestamp: currentTimestamp))
                
                // Check if unlock conditions are met
                UnlockManager.shared.unlockIfNeeded()
            }
        }
    }

    // Other necessary WCSessionDelegate methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // print("Session activated with state: \(activationState)")
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        // print("WCSession did become inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate() // Reactivating the session
        // print("WCSession did deactivate and was reactivated")
    }
    
    func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error)")
            }
        }
    }
}
