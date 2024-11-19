import Foundation
import WatchConnectivity

class WatchAccelerometer: ObservableObject {
    static let shared = WatchAccelerometer()
    @Published var coordinates: [(x: Double, y: Double, z: Double, timestamp: Date)] = [] // Current Apple watch coordinates
    
    func updateCoordinates(receivedCoordinate: (x: Double, y: Double, z: Double, timestamp: Date)) {
        coordinates.append(receivedCoordinate)
        
        // Limit the array size if needed to avoid excessive memory usage
        if coordinates.count > 200 { // For example, keep only the latest 200 samples (0.02 * 200 = 4 seconds)
            coordinates.removeFirst()
        }
    }
}
