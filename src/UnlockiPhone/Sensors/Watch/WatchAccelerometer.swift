import Foundation
import WatchConnectivity

class WatchAccelerometer: ObservableObject {
    static let shared = WatchAccelerometer()
    @Published var coordinates: [(x: Double, y: Double, z: Double, timestamp: Date)] = [] // Current Apple watch coordinates
    
    func updateCoordinates(receivedCoordinates: (x: Double, y: Double, z: Double, timestamp: Date)) {
        coordinates.append(receivedCoordinates)
        
        // Limit the array size if needed to avoid excessive memory usage
        if coordinates.count > 50 { // For example, keep only the latest 50 values
            coordinates.removeFirst()
        }
    }
}
