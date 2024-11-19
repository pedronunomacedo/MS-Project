import Foundation
import WatchConnectivity

class WatchQuaternion: ObservableObject {
    static let shared = WatchQuaternion()
    @Published var quaternionHistory: [(w: Double, x: Double, y: Double, z: Double, timestamp: Date)] = [] // Current Apple watch coordinates
    
    func updateQuaternions(quaternion: (w: Double, x: Double, y: Double, z: Double, timestamp: Date)) {
        self.quaternionHistory.append(quaternion)
        
        // Limit the history size to save memory (we will only keep the last 200 quaternions)
        if self.quaternionHistory.count > 200 {
            self.quaternionHistory.removeFirst()
        }
    }
}
