import Foundation
import WatchConnectivity
import UserNotifications

class UnlockManager {
    static let shared = UnlockManager()  // Singleton instance
    var phoneUnlocked = false
    @Published var phoneUnlocks: Int = 0
    
    private var lastUnlockAttempt: Date? = nil
    private let minimumInterval: TimeInterval = 1  // Minimum time interval between unlock attempts in seconds
    
    func unlockIfNeeded() {
        print("Unlock if needed!")
        guard !self.phoneUnlocked else { return } // Prevent multiple notifications
        
//        let currentTime = Date()
//        if let lastUnlockAttempt = self.lastUnlockAttempt,
//           currentTime.timeIntervalSince(lastUnlockAttempt) < minimumInterval {
//            print("Unlock attempt throttled.")
//            return
//        }
//        
//        self.lastUnlockAttempt = currentTime
        
        if self.shouldUnlock() {
            self.performUnlock()
            // self.phoneUnlocked = true // TODO: Uncomment when project is done!
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
        
        // Cehck if at least one device is stationary (acceleratin near 0)
//        if self.checkIfDevicesAreStationary(alignedAccelerations: alignedAccelerations) {
//            print("Devices are stationary. No unlock necessary.")
//            return false
//        }

        // Step 2: Check if both alignment and stability conditions are met
        let quaternionsAligned = ProcessQuaternions.shared.verifyAlignment(with: alignedQuaternions)
        let accelerationStable = ProcessAcceleration.shared.verifyStability(with: alignedAccelerations)
        
        print("quaternionsAligned: ", quaternionsAligned)
        print("accelerationStable: ", accelerationStable)
        
        // Condition for unlocking based on alignment and stability
        return quaternionsAligned && accelerationStable
    }
    
    private func checkIfDevicesAreStationary(alignedAccelerations: [(watch: Acceleration, iPhone: Acceleration)]) -> Bool {
        // Define a small epsilon value to consider as zero acceleration
        let epsilon = 0.05  // Threshold for considering values as zero

        let isStationary = alignedAccelerations.allSatisfy { pair in
            // Check both watch and iPhone accelerations
            let watchAcceleration = pair.watch
            let iphoneAcceleration = pair.iPhone
            return (abs(watchAcceleration.x) <= epsilon && abs(watchAcceleration.y) <= epsilon && abs(watchAcceleration.z) <= 1.0 + epsilon) || 
            (abs(iphoneAcceleration.x) <= epsilon && abs(iphoneAcceleration.y) <= epsilon && abs(iphoneAcceleration.z) <= 1.0 + epsilon)
        }

        return isStationary
    }
    
    private func incrementPhoneUnlocks() {
        DispatchQueue.main.async {
            self.phoneUnlocks += 1
        }
    }   
    
    private func performUnlock() {
        if self.phoneUnlocked { return } // Guard to prevent multiple unlocks
        
        // Notify the user with a local notification
        let content = UNMutableNotificationContent()
        content.title = "Unlock Conditions Met"
        content.body = "The unlock conditions are met. You can now unlock your iPhone."
        content.sound = UNNotificationSound.default
        
        // Set a trigger with a slight delay
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "UnlockNotification", content: content, trigger: trigger)
            
        print("Triggering notification on iPhone!")
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error displaying notification: \(error.localizedDescription)")
            } else {
                print("Notification added successfully!")
                self.incrementPhoneUnlocks()
                // self.sendUnlockMessageToAppleWatch()
            }
        }
    }
    
    private func sendUnlockMessageToAppleWatch() {
        print("Sending unlock iPhone confirmation to the watch!")
        
        let message : [String: String] = [
            "unlockiPhoneStatus": "unlocked"
        ]
        
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("Failed to send message to Apple Watch: \(error.localizedDescription)")
        }
    }
}
