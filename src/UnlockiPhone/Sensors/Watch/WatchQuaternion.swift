import Foundation
import WatchConnectivity

class WatchQuaternion: ObservableObject {
    static let shared = WatchQuaternion()
    @Published var quaternionHistory: [Quaternion] = [] // Current Apple watch coordinates
    private let quaternionsQueue = DispatchQueue(label: "com.example.watchQuaternions")
    
    func updateQuaternions(quaternions: [Quaternion]) {
        quaternionsQueue.async { // Ensure all updates are serialized
            let newQuaternions = quaternions
            var updatedQuaternions = self.quaternionHistory
            updatedQuaternions.append(contentsOf: newQuaternions) // newQuaternions/window will have 100 samples (and updatedQuaternions will have 200 + 100 = 300 samples)
            
            if updatedQuaternions.count > 200 { // Keep only the latest 200 samples
                updatedQuaternions.removeFirst(updatedQuaternions.count - 200) // Remove the first 100 elements (the last 100 samples will be kept because it's the next sliding window)
            }
            
            DispatchQueue.main.async { // Switch to main thread to update @Published property
                self.quaternionHistory = updatedQuaternions
            }
        }
    }
}
