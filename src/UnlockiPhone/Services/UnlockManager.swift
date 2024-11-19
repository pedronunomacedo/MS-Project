import Foundation
import WatchConnectivity
import UserNotifications

class UnlockManager {
    static let shared = UnlockManager()  // Singleton instance
    var phoneUnlocked = false;
    
    func unlockIfNeeded() {
        print("Unlock if needed!")
        if !self.phoneUnlocked {
            if self.shouldUnlock() {
                self.performUnlock()
                self.sendUnlockMessageToAppleWatch()
                self.phoneUnlocked = true
            }
        }
    }
    
    func shouldUnlock() -> Bool {
        print("Should unlock?")
        // Step 1: Run the process function to prepare and align quaternions
        guard let alignedQuaternions = ProcessQuaternions.shared.process() else {
            return false  // Not enough data to proceed
        }
        
        print("alignedQuaternions.count: ", alignedQuaternions.count)
        
        guard let alignedAccelerations = ProcessAcceleration.shared.process() else {
            return false  // Not enough data to proceed
        }
        
        print("alignedAccelerations.count: ", alignedAccelerations.count)

        // Step 2: Check if both alignment and stability conditions are met
        let quaternionsAligned = ProcessQuaternions.shared.verifyAlignment(with: alignedQuaternions)
        let accelerationStable = ProcessAcceleration.shared.verifyStability(with: alignedAccelerations)
        
        print("quaternionsAligned: ", quaternionsAligned)
        print("accelerationStable: ", accelerationStable)
        
        // Condition for unlocking based on alignment and stability
        return quaternionsAligned && accelerationStable
    }
    
    private func performUnlock() {
        // Notify the user with a local notification
        let content = UNMutableNotificationContent()
        content.title = "Unlock Conditions Met"
        content.body = "The unlock conditions are met. You can now unlock your iPhone."
        content.sound = UNNotificationSound.default
        
        // Set a trigger with a slight delay
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "UnlockNotification", content: content, trigger: trigger)
            
        print("Triggering notification on iPhone!")
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error.localizedDescription)")
                return
            } else {
                print("Notification permission granted: \(granted)")
            }
        }
                
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error displaying notification: \(error.localizedDescription)")
            }
        }
    }
    
    private func sendUnlockMessageToAppleWatch() {
        print("Sending unlock iPhone confirmation to the watch!")
        
        let message = ["unlockiPhoneStatus": "unlocked"]
        
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("Failed to send message to Apple Watch: \(error.localizedDescription)")
        }
    }
}
